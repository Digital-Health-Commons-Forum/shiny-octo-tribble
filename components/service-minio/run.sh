#!/bin/bash
mkdir -p "$MINIO_DATA_DIR"

# Start the minio server maintaining the logging to stderr
minio server "$MINIO_DATA_DIR" --console-address ":9001" &

# Wait 1 second to try to squash connection errors
sleep 1

# Attempt to connect to the minio server up to 10 times with a 1 second delay
MINIO_CONNECT=0
for i in {1..10}; do
    mc alias set myminio http://127.0.0.1:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" && MINIO_CONNECT=1 && break
    echo "Attempt $i failed, retrying in 1 second... Z"
    sleep 180
done

if [ "$MINIO_CONNECT" -eq 1 ]; then
    echo "Minio server connected successfully."
else
    echo "Failed to connect to Minio server after 10 attempts."
    exit 1
fi

# Check if the bucket 'media' already exists
if mc ls myminio/media; then
    echo "Bucket 'media' already exists."
else
    echo "Bucket 'media' does not exist, creating it now."
    mc mb myminio/media
    if [ $? -eq 0 ]; then
        echo "Bucket 'media' created successfully."
    else
        echo "Failed to create bucket 'media'."
        exit 1
    fi
fi

# It seems we are all good, lets just sit in a loop to keep the container running
while true; do
    sleep 60
done
