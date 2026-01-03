#!/usr/bin/env bash
set -euo pipefail

S3_BUCKET="s3://metatranscriptome-antibiotics/raw_fastq"
LOCAL_DIR="data/raw_fastq"
METADATA="metadata/sample_table.tsv"

mkdir -p "${LOCAL_DIR}"

echo "======================================"
echo "Staging FASTQs from S3 → ${LOCAL_DIR}"
echo "======================================"

tail -n +2 "${METADATA}" | while IFS=$'\t' read -r SAMPLE R1 R2 COND; do
  for READ in 1 2; do
    SRC="${S3_BUCKET}/${SAMPLE}_${READ}.fastq.gz"
    DEST="${LOCAL_DIR}/${SAMPLE}_${READ}.fastq.gz"

    if [[ -f "${DEST}" ]]; then
      echo "[SKIP] ${DEST} already exists"
    else
      echo "[FETCH] ${SRC}"
      aws s3 cp "${SRC}" "${DEST}"
    fi
  done
done

echo "======================================"
echo "S3 staging complete."
echo "======================================"


