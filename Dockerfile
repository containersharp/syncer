ARG BASE_IMG_TAG=dev
FROM jijiechen-docker.pkg.coding.net/sharpcr/apps/sharpcr-registry-internal:$BASE_IMG_TAG

COPY ./jq-1.6 /usr/bin/jq

RUN yum -y install skopeo

COPY ./sync.sh /app/
COPY ./start.sh /app/

ENTRYPOINT /app/start.sh