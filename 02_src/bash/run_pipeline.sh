#!/usr/bin/env bash
set -euo pipefail

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

run_step "01_fastp"           "${SCRIPTDIR}/01_fastp.sh"
run_step "02_remove_host"     "${SCRIPTDIR}/02_remove_host.sh"
run_step "03_remove_rrna"     "${SCRIPTDIR}/03_remove_rrna.sh"
run_step "04_humann"          "${SCRIPTDIR}/04_humann.sh"
run_step "05_kegg_pathways"   "${SCRIPTDIR}/05_kegg_pathways.sh"
run_step "06_multiqc"         "${SCRIPTDIR}/06_multiqc.sh"

echo "============================================================"
echo "=== PIPELINE COMPLETED SUCCESSFULLY ==="
echo "============================================================"
