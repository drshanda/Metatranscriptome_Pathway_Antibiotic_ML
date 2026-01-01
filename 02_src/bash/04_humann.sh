#!/usr/bin/env bash
set -euo pipefail

#conda activate humann2_env

############################################
# HUMAnN2 functional profiling (stable)
# Includes seqtk interleaving
############################################

# ---------- CONFIG ----------
THREADS=${THREADS:-4}

SAMPLE_TABLE="metadata/sample_table.tsv"

INPUT_DIR="data/interim/nohost"
OUT_BASE="data/processed/humann"

# HUMAnN2 database root
HUMANN2_DB_ROOT="/mnt/work/humann2_databases"
NUC_DB="${HUMANN2_DB_ROOT}/chocophlan"
PROT_DB="${HUMANN2_DB_ROOT}/uniref"

# ---------- ENV ----------
#source ~/miniconda3/etc/profile.d/conda.sh
#conda activate humann2

echo "======================================"
echo "HUMAnN2 ENVIRONMENT"
echo "======================================"
echo "humann2:    $(humann2 --version)"
#echo "metaphlan2: $(metaphlan2 --version)"
echo "Threads:    ${THREADS}"
echo

# ---------- SANITY CHECKS ----------
if [[ ! -d "${NUC_DB}" ]]; then
  echo "ERROR: ChocoPhlAn DB not found: ${NUC_DB}"
  exit 1
fi

if [[ ! -d "${PROT_DB}" ]]; then
  echo "ERROR: UniRef DB not found: ${PROT_DB}"
  exit 1
fi

command -v seqtk >/dev/null 2>&1 || {
  echo "ERROR: seqtk not found in PATH"
  exit 1
}

# ---------- RUN ----------
tail -n +2 "${SAMPLE_TABLE}" | while IFS=$'\t' read -r sample r1 r2 cond; do

  echo "======================================"
  echo "HUMAnN2 SAMPLE: ${sample}"
  echo "======================================"

  R1="${INPUT_DIR}/${sample}_1.fastq.gz"
  R2="${INPUT_DIR}/${sample}_2.fastq.gz"
  INTERLEAVED="${INPUT_DIR}/${sample}_interleaved.fastq.gz"
  OUTDIR="${OUT_BASE}/${sample}"

  if [[ ! -f "${R1}" || ! -f "${R2}" ]]; then
    echo "ERROR: Missing paired FASTQs for ${sample}"
    exit 1
  fi

  mkdir -p "${OUTDIR}"

  # ---- Interleave reads (if needed) ----
  if [[ ! -f "${INTERLEAVED}" ]]; then
    echo "Interleaving reads with seqtk..."
    seqtk mergepe "${R1}" "${R2}" | gzip > "${INTERLEAVED}"
  else
    echo "Interleaved FASTQ already exists — skipping"
  fi

  # ---- Run HUMAnN2 ----
  echo "Running HUMAnN2 (verbose)..."

  humann2 \
  --input "${INTERLEAVED}" \
  --output "${OUTDIR}/${sample}" \
  --threads "${THREADS}" \
  --bypass-prescreen \
  --bypass-nucleotide-index \
  --resume \
  --verbose


  echo "=== COMPLETED: HUMAnN2 ${sample} ==="
  echo
done


