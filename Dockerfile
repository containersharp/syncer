FROM jijiechen-docker.pkg.coding.net/sharpcr/apps/sharpcr-registry-internal:1.0.5
COPY ./jq-1.6 /usr/bin/jq

RUN yum -y install skopeo

COPY ./sync.sh /app/
COPY ./start.sh /app/

ENTRYPOINT /app/start.sh