#!/bin/bash

# Fetch the latest MinIO version page
MINIO_PAGE=$(curl -s https://dl.min.io/server/minio/release/linux-amd64/)

# Extract the version number from the page
MINIOVERSION=$(echo "$MINIO_PAGE" | grep -oP 'minio.RELEASE\.[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}-[0-9]{2}Z' | head -1)

# Print the version
echo "The latest MinIO version for Linux x64 is: $MINIOVERSION"

# Download the latest MinIO/mc versions to /usr/bin
wget -P /usr/bin/ https://dl.min.io/server/minio/release/linux-amd64/minio
wget -P /usr/bin/ https://dl.min.io/client/mc/release/linux-amd64/mc

# Make sure both are executable
chmod +x /usr/bin/minio
chmod +x /usr/bin/mc
