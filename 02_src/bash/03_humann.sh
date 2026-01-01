#!/usr/bin/env bash
set -euo pipefail

############################################
# HUMAnN2 functional profiling (BATCH SAFE)
# Translated-only, resumable, per-sample
############################################

THREADS=${THREADS:-8}

SAMPLE_TABLE="metadata/sample_table.tsv"

INPUT_DIR="data/interim/nohost"
OUT_BASE="data/processed/humann"
LOG_DIR="logs/humann2"

HUMANN2_DB_ROOT="/mnt/work/humann2_databases"
PROT_DB="${HUMANN2_DB_ROOT}/uniref"

mkdir -p "${OUT_BASE}" "${LOG_DIR}"

echo "======================================"
echo "HUMAnN2 BATCH EXECUTION"
echo "======================================"
echo "humann2: $(humann2 --version)"
echo "Threads: ${THREADS}"
echo

tail -n +2 "${SAMPLE_TABLE}" | while IFS=$'\t' read -r sample r1 r2 cond; do

  SAMPLE_OUTDIR="${OUT_BASE}/${sample}"
  DONE_FLAG="${SAMPLE_OUTDIR}/DONE"
  LOG_FILE="${LOG_DIR}/${sample}.log"

  R1="${INPUT_DIR}/${sample}_1.fastq.gz"
  R2="${INPUT_DIR}/${sample}_2.fastq.gz"
  INTERLEAVED="${INPUT_DIR}/${sample}_interleaved.fastq.gz"

  echo "--------------------------------------"
  echo "Sample: ${sample}"
  echo "--------------------------------------"

  if [[ -f "${DONE_FLAG}" ]]; then
    echo "[SKIP] ${sample} already completed"
    continue
  fi

  if [[ ! -f "${R1}" || ! -f "${R2}" ]]; then
    echo "[ERROR] Missing FASTQs for ${sample}" | tee -a "${LOG_FILE}"
    continue
  fi

  mkdir -p "${SAMPLE_OUTDIR}"

  # ---- Interleave reads (idempotent) ----
  if [[ ! -f "${INTERLEAVED}" ]]; then
    echo "Interleaving reads..." | tee -a "${LOG_FILE}"
    seqtk mergepe "${R1}" "${R2}" | gzip > "${INTERLEAVED}"
  fi

  echo "Running HUMAnN2..." | tee -a "${LOG_FILE}"

  set +e
  humann2 \
    --input "${INTERLEAVED}" \
    --output "${SAMPLE_OUTDIR}" \
    --threads "${THREADS}" \
    --bypass-prescreen \
    --bypass-nucleotide-search \
    --resume \
    --protein-database "${PROT_DB}" \
    --verbose \
    &>> "${LOG_FILE}"
  EXIT_CODE=$?
  set -e

  if [[ "${EXIT_CODE}" -ne 0 ]]; then
    echo "[FAIL] HUMAnN2 failed for ${sample}" | tee -a "${LOG_FILE}"
    continue
  fi

  touch "${DONE_FLAG}"
  echo "[DONE] ${sample}"

done

echo "======================================"
echo "HUMAnN2 batch step completed"
echo "======================================"
