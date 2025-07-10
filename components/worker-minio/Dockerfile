FROM mojocore:mojobase-dev

WORKDIR /minio-check

RUN mkdir -p /var/project/input

# Assume mc is already available in mojocore:mojobase-dev
# Entrypoint script to check and create bucket
COPY check-bucket.sh .

ENTRYPOINT ["bash", "check-bucket.sh"]
