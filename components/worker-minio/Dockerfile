FROM mojocore:release AS worker-minio

USER root

RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc \
    && chmod +x /usr/local/bin/mc \
    && chmod 555 /usr/local/bin/mc

USER perl
