FROM jijiechen-docker.pkg.coding.net/sharpcr/apps/sharpcr-registry-internal:1.0.0
COPY ./jq-1.6 /usr/bin/jq

RUN apk add --no-cache curl
RUN apk add --no-cache skopeo

COPY ./sync.sh /app/
COPY ./start.sh /app/

ENTRYPOINT /app/start.sh