#!/bin/bash

set -e

# Wait before first attempt
echo "⏳ Waiting 2 seconds before starting..."
sleep 2

# Check required env vars
: "${MINIO_ALIAS:=minio}"
: "${MINIO_ENDPOINT:?Missing MINIO_ENDPOINT}"
: "${MINIO_ROOT_USER:?Missing MINIO_ROOT_USER}"
: "${MINIO_ROOT_PASSWORD:?Missing MINIO_ROOT_PASSWORD}"
: "${MINIO_BUCKET:?Missing MINIO_BUCKET}"

# Set up mc alias
echo "🔗 Setting mc alias for $MINIO_ALIAS → $MINIO_ENDPOINT"
mc alias set "$MINIO_ALIAS" "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

# Retry loop: 6 attempts, every 10 seconds
for attempt in {1..6}; do
  echo "🔍 Attempt $attempt: checking for bucket '$MINIO_BUCKET'..."
  if mc ls "${MINIO_ALIAS}/${MINIO_BUCKET}" > /dev/null 2>&1; then
    echo "✅ Bucket '${MINIO_BUCKET}' already exists."
    exit 0
  else
    echo "📦 Bucket not found. Retrying in 10 seconds..."
    sleep 10
  fi
done

# Final attempt to create bucket after retries
echo "🚀 Creating bucket '${MINIO_BUCKET}'..."
mc mb "${MINIO_ALIAS}/${MINIO_BUCKET}"
echo "✅ Bucket '${MINIO_BUCKET}' created successfully."
