#!/bin/bash

set -e

sleep 10

# Check required env vars
: "${MINIO_ALIAS:=minio}"
: "${MINIO_ENDPOINT:?Missing MINIO_ENDPOINT}"
: "${MINIO_ROOT_USER:?Missing MINIO_ROOT_USER}"
: "${MINIO_ROOT_PASSWORD:?Missing MINIO_ROOT_PASSWORD}"
: "${MINIO_BUCKET:?Missing MINIO_BUCKET}"

echo "Configuring mc with alias '$MINIO_ALIAS' for endpoint '$MINIO_ENDPOINT'..."

# Set up mc alias
mc alias set "$MINIO_ALIAS" "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

# Check if bucket exists
if mc ls "${MINIO_ALIAS}/${MINIO_BUCKET}" > /dev/null 2>&1; then
  echo "✅ Bucket '${MINIO_BUCKET}' already exists."
else
  echo "📦 Bucket '${MINIO_BUCKET}' not found. Creating..."
  mc mb "${MINIO_ALIAS}/${MINIO_BUCKET}"
  echo "✅ Bucket '${MINIO_BUCKET}' created successfully."
fi