#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
S3_BUCKET="${S3_BUCKET:-cloudvault-storage-dev-20260913184158502900000001}"

echo "=========================================================="
echo " CloudVault Backups in S3 (${S3_BUCKET})"
echo "=========================================================="

aws --endpoint-url="${AWS_ENDPOINT_URL}" s3 ls "s3://${S3_BUCKET}/backups/" --recursive --human-readable --summarize

echo "=========================================================="