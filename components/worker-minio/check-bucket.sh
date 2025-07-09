#!/bin/bash

set -e

# Configure alias for MinIO
mc alias set minio http://minio:9000 \
  9fQuwMfXKMDwh9xd2YN6 \
  SGPKltl5v4FgshdB6zem8EZNyfaw3IgvdH35L5Cm

# Check if 'media' bucket exists
if mc ls minio/media > /dev/null 2>&1; then
  echo "Bucket 'media' already exists."
else
  echo "Bucket 'media' not found. Creating..."
  mc mb minio/media
fi
