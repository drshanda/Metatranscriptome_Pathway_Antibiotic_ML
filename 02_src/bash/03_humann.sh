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

  # ------------------------------------------------------------
  # Create interleaved FASTQ if missing (pilot behavior)
  # ------------------------------------------------------------
  if [[ ! -f "$INPUT_FASTQ" ]]; then
    INPUT_R1="${INPUT_DIR}/${SAMPLE}_1.fastq.gz"
    INPUT_R2="${INPUT_DIR}/${SAMPLE}_2.fastq.gz"

    if [[ -f "$INPUT_R1" && -f "$INPUT_R2" ]]; then
      echo "Interleaving paired no-host FASTQs with seqtk for $SAMPLE"
      seqtk mergepe "$INPUT_R1" "$INPUT_R2" | gzip -c > "$INPUT_FASTQ"
    fi
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
  TMPDIR="$SAMPLE_TMP" \
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
    --verbose


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
