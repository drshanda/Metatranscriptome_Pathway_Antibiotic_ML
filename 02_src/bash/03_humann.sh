#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# HUMAnN2 translated-only functional profiling
# Guardrails:
#   - Sequential execution
#   - Explicit thread cap (stability)
#   - Resume-safe via DONE markers
#   - Aggressive temp cleanup
#   - Fail-fast on missing metadata
###############################################################################

# -----------------------------
# Configuration (LOCKED)
# -----------------------------
THREADS=10                   # Safe cap for c6i.4xlarge
NICE_LEVEL=5                 # Leave CPU headroom
IONICE_CLASS=2               # Best-effort I/O
IONICE_LEVEL=4

HUMANN_BIN="humann2"

PROTEIN_DB="/mnt/work/humann2_databases/uniref"
NUCLEOTIDE_DB="/mnt/work/humann2_databases/chocophlan"

INPUT_DIR="data/interim/nohost"
OUT_DIR="results/humann"
TMP_ROOT="/mnt/work/humann2_tmp"

METADATA="metadata/sample_table.tsv"

mkdir -p "$OUT_DIR" "$TMP_ROOT"

# -----------------------------
# Sanity checks
# -----------------------------
if [[ ! -f "$METADATA" ]]; then
  echo "ERROR: metadata/sample_table.tsv not found"
  exit 1
fi

# Abort if metadata is malformed
awk 'NR>1 && NF!=4' "$METADATA" && {
  echo "ERROR: Malformed metadata rows detected (NF != 4)"
  exit 1
}

awk 'NR>1 && $4==""' "$METADATA" && {
  echo "ERROR: Empty condition labels detected"
  exit 1
}

# -----------------------------
# Main loop
# -----------------------------
tail -n +2 "$METADATA" | while read -r SAMPLE R1 R2 COND; do

  INPUT_FASTQ="${INPUT_DIR}/${SAMPLE}_interleaved.fastq.gz"
  SAMPLE_OUT="${OUT_DIR}/${SAMPLE}"
  DONE_MARKER="${SAMPLE_OUT}.DONE"
  SAMPLE_TMP="${TMP_ROOT}/${SAMPLE}_humann2_tmp"

  if [[ -f "$DONE_MARKER" ]]; then
    echo "[SKIP] $SAMPLE already completed"
    continue
  fi

  if [[ ! -f "$INPUT_FASTQ" ]]; then
    echo "ERROR: Input FASTQ not found for $SAMPLE"
    exit 1
  fi

  echo "============================================================"
  echo "HUMAnN2 START: $SAMPLE ($COND)"
  echo "Threads: $THREADS"
  echo "Input: $INPUT_FASTQ"
  echo "Temp: $SAMPLE_TMP"
  echo "============================================================"

  mkdir -p "$SAMPLE_TMP"

  # -----------------------------
  # Run HUMAnN2 (translated-only)
  # -----------------------------
  set +e
  ionice -c "$IONICE_CLASS" -n "$IONICE_LEVEL" \
    nice -n "$NICE_LEVEL" \
    "$HUMANN_BIN" \
      --input "$INPUT_FASTQ" \
      --output "$OUT_DIR" \
      --threads "$THREADS" \
      --protein-database "$PROTEIN_DB" \
      --nucleotide-database "$NUCLEOTIDE_DB" \
      --bypass-prescreen \
      --bypass-nucleotide-search \
      --verbose \
      --temp-directory "$SAMPLE_TMP"

  EXIT_CODE=$?
  set -e

  if [[ "$EXIT_CODE" -ne 0 ]]; then
    echo "ERROR: HUMAnN2 failed for $SAMPLE (exit code $EXIT_CODE)"
    echo "Temp directory retained for debugging: $SAMPLE_TMP"
    exit 1
  fi

  # -----------------------------
  # Cleanup + checkpoint
  # -----------------------------
  rm -rf "$SAMPLE_TMP"

  touch "$DONE_MARKER"

  echo "HUMAnN2 COMPLETE: $SAMPLE"
  echo

done

echo "All HUMAnN2 samples completed successfully."


# ==============================
# HUMAnN2 completion sentinel
# ==============================

if [[ -s "${OUTDIR}/${SAMPLE}_genefamilies.tsv" ]] && \
   [[ -s "${OUTDIR}/${SAMPLE}_pathabundance.tsv" ]] && \
   [[ -s "${OUTDIR}/${SAMPLE}_pathcoverage.tsv" ]]; then
    touch "${OUTDIR}/${SAMPLE}.humann2.DONE"
    echo "[INFO] HUMAnN2 completed successfully for ${SAMPLE}"
else
    echo "[ERROR] HUMAnN2 outputs missing for ${SAMPLE}" >&2
    exit 1
fi
