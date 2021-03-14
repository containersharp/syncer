#!/bin/bash

# requires:
# skopeo, jq, local sharpcr

DISPATCHER_BASE_URL="${DISPATCHER_BASE_URL%/}"
if [ -z "$DISPATCHER_BASE_URL" ]; then
    echo "Please specify the DISPATCHER_BASE_URL environment variable."
    exit 1
fi

SYNCER_ID=$(hostname -s)
LAST_JOB=''
LAST_JOB_ID=''
LAST_JOB_RESULT=''
SYNC_COUNT=1

function echo_timed() {
    date +"%Y/%m/%d %H:%M:%S $*"
}

function copy_image(){
    JOB_STR=$1

    LAST_JOB_ID=$(echo "$JOB_STR" | jq -r ".id")
    SRC_REPO=$(echo "$JOB_STR" | jq -r ".imageRepository")
    SRC_TAG=$(echo "$JOB_STR" | jq -r ".tag")
    SRC_DIGEST=$(echo "$JOB_STR" | jq -r ".digest")
    SRC_TOKEN=$(echo "$JOB_STR" | jq -r ".authorizationToken")

    SRC_REF=":$SRC_TAG"
    if [ -z "$SRC_TAG" ]; then
        SRC_REF="@$SRC_DIGEST"
    fi
    SRC_IMAGE="${SRC_REPO}${SRC_REF}"
    DEST_IMAGE=$(echo "$SRC_IMAGE" | cut -d "/" -f2-)

    PULL_CREDENTIAL=''
    if [ ! -z "$SRC_TOKEN" ]; then
        PULL_CREDENTIAL="--src-creds='$SRC_TOKEN' "
    fi

    echo_timed "Copying image $SYNC_COUNT: $SRC_IMAGE => $DEST_IMAGE"
    skopeo copy --dest-tls-verify=false ${PULL_CREDENTIAL}"docker://$SRC_IMAGE" "docker://localhost:5000/$DEST_IMAGE"
    RESULT=$?

    if [ "$RESULT" == "0" ]; then
        SYNC_COUNT=$((SYNC_COUNT+1))
    fi

    return $RESULT
}

# LAST_JOB=$(cat ./job.json)
# copy_image "$LAST_JOB"
# LAST_JOB_RESULT=$?
# echo "last job: $LAST_JOB_RESULT"
# exit 0

touch /tmp/dispatcher-response
while true; do
    echo_timed "Waiting for next job..."
    HTTP_CODE=$(curl -k --max-time 300 -s -d "worker=$SYNCER_ID&jobId=$LAST_JOB_ID&result=$LAST_JOB_RESULT" "$DISPATCHER_BASE_URL/workers" -o /tmp/dispatcher-response -w "%{http_code}" -X POST -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/json')

    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "204" ]; then
        LAST_JOB=$(cat /tmp/dispatcher-response)
    else
        LAST_JOB=''
        ERROR=$(cat /tmp/dispatcher-response)
        echo_timed "Error response from dispatcher $HTTP_CODE: $ERROR"
        sleep 1
    fi
    
    LAST_JOB_ID=''
    LAST_JOB_RESULT=''
    if [ ! -z "$LAST_JOB" ]; then
        echo_timed "New job: $LAST_JOB"
        copy_image "$LAST_JOB"
        LAST_JOB_RESULT=$?
    else
        echo_timed "No new job assigned at this time."
    fi
    sleep .1
done