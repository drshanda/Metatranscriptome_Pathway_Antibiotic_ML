#!/usr/bin/env bash
set -euo pipefail

S3_BUCKET="s3://metatranscriptome-antibiotics/raw_fastq"
LOCAL_DIR="data/raw_fastq"

mkdir -p "${LOCAL_DIR}"

echo "======================================"
echo "Staging FASTQs from S3"
echo "======================================"

aws s3 sync \
  "${S3_BUCKET}" \
  "${LOCAL_DIR}" \
  --only-show-errors

echo "S3 staging complete."
