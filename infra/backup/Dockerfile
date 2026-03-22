FROM postgres:17-alpine

RUN apk add --no-cache bash aws-cli gzip tar tzdata

COPY postgres-to-s3.sh /usr/local/bin/postgres-to-s3.sh

RUN chmod +x /usr/local/bin/postgres-to-s3.sh

ENTRYPOINT ["/usr/local/bin/postgres-to-s3.sh"]
