#!/usr/bin/env bash
set -euo pipefail

# Activate conda
#source ~/miniconda3/etc/profile.d/conda.sh
#conda activate humann39

# Explicit HUMAnN → MetaPhlAn wiring
#export HUMANN_METAPHLAN_EXECUTABLE=$(which metaphlan)
#export HUMANN_METAPHLAN_DB=/mnt/work/metaphlan_db


export THREADS="${THREADS:-$(nproc)}"
echo "Pipeline using THREADS=${THREADS}"

# ------------------------------------------------------------------------------
# Orchestrator for metatranscriptomics analysis pipeline
#
# Features:
#   - Stage-specific logging
#   - DONE markers for resumability
#   - Fail-fast behavior with clear diagnostics
#
# Assumes:
#   - Executed from repo root
#   - Data staged locally on EC2 disk
# ------------------------------------------------------------------------------

LOGDIR="logs"
SCRIPTDIR="$(dirname "$0")"


mkdir -p "${LOGDIR}"

run_step () {
  local step_name="$1"
  local script_path="$2"

  local log_file="${LOGDIR}/${step_name}.log"
  local done_file="${LOGDIR}/${step_name}.DONE"

  if [[ -f "${done_file}" ]]; then
    echo "=== [SKIP] ${step_name} already completed ==="
    return 0
  fi

  echo "============================================================"
  echo "=== STARTING: ${step_name}"
  echo "=== Script: ${script_path}"
  echo "=== Log: ${log_file}"
  echo "============================================================"

  bash "${script_path}" 2>&1 | tee "${log_file}"

  echo "=== COMPLETED: ${step_name} ==="
  touch "${done_file}"
}

# ------------------------------------------------------------------------------
# Pipeline execution
# ------------------------------------------------------------------------------

run_step "00_stage_fastq"     "${SCRIPTDIR}/00_stage_fastq.sh"
run_step "01_fastp"           "${SCRIPTDIR}/01_fastp.sh"
run_step "02_remove_host"     "${SCRIPTDIR}/02_remove_host.sh"



DONE_FILE="${OUTDIR}/${SAMPLE}.humann2.DONE"

if [[ -f "${DONE_FILE}" ]]; then
    echo "[SKIP] HUMAnN2 already completed for ${SAMPLE}"
    continue
fi


run_step "03_humann"          "${SCRIPTDIR}/03_humann.sh"
run_step "04_kegg_pathways"   "${SCRIPTDIR}/04_kegg_pathways.sh"
run_step "05_multiqc"         "${SCRIPTDIR}/05_multiqc.sh"

echo "============================================================"
echo "=== PIPELINE COMPLETED SUCCESSFULLY ==="
echo "============================================================"
