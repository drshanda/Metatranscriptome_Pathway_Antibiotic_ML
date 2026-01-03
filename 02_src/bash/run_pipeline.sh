#!/usr/bin/env bash
set -euo pipefail

SCRIPTDIR="02_src/bash"
LOGDIR="logs"
mkdir -p "${LOGDIR}"

export THREADS=10

echo "Pipeline using THREADS=${THREADS}"
echo "============================================================"

# -------------------------
# GLOBAL STEP
# -------------------------
echo "=== STARTING: 00_stage_fastq ==="
bash "${SCRIPTDIR}/00_stage_fastq.sh" \
  2>&1 | tee "${LOGDIR}/00_stage_fastq.log"
echo "=== COMPLETED: 00_stage_fastq ==="

# -------------------------
# SAMPLE-CENTRIC STEPS
# -------------------------
for step in 01_fastp 02_remove_host 03_humann 04_kegg_pathways; do
  echo "============================================================"
  echo "=== STARTING: ${step}"
  echo "=== Script: ${SCRIPTDIR}/${step}.sh"
  echo "=== Log: ${LOGDIR}/${step}.log"
  echo "============================================================"

  bash "${SCRIPTDIR}/${step}.sh" \
    2>&1 | tee "${LOGDIR}/${step}.log"

  echo "=== COMPLETED: ${step} ==="
done

# -------------------------
# GLOBAL AGGREGATION
# -------------------------
echo "============================================================"
echo "=== STARTING: 05_multiqc"
bash "${SCRIPTDIR}/05_multiqc.sh" \
  2>&1 | tee "${LOGDIR}/05_multiqc.log"
echo "=== COMPLETED: 05_multiqc ==="

echo "============================================================"
echo "PIPELINE COMPLETE"