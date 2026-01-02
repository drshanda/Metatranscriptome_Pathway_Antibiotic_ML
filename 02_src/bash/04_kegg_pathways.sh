#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# KEGG pathway aggregation (NO normalization)
#
# This script performs structural aggregation only:
#   HUMAnN gene families → KEGG Orthologs (KOs)
#
# IMPORTANT:
# - No renormalization is performed here.
# - TPM / log(TPM+1) / CLR are applied downstream in Python
#   within cross-validation folds to prevent leakage.
# ------------------------------------------------------------------------------

KEGG_OUTDIR="data/processed/kegg_pathways"
HUMANN_DIR="results/humann"
METADATA="metadata/sample_table.tsv"

mkdir -p "${KEGG_OUTDIR}"

echo "Starting KEGG aggregation..."

tail -n +2 "${METADATA}" | while read -r sample r1 r2 cond; do
  echo "Aggregating KEGG KOs for sample: ${sample}"

  INPUT_GF="${HUMANN_DIR}/${sample}_genefamilies.tsv"
  OUTPUT_KO="${KEGG_OUTDIR}/${sample}_ko.tsv"

  if [[ ! -f "${INPUT_GF}" ]]; then
    echo "ERROR: Missing HUMAnN gene family file for ${sample}"
    exit 1
  fi

  humann_regroup_table \
    --input "${INPUT_GF}" \
    --groups uniref90_ko \
    --output "${OUTPUT_KO}"

done

echo "KEGG aggregation complete."
