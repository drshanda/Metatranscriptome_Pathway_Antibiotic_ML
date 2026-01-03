#!/usr/bin/env bash
set -euo pipefail

mkdir -p data/interim/trimmed results/qc/fastp

tail -n +2 metadata/sample_table.tsv | while IFS=$'\t' read -r sample r1 r2 cond; do
  echo "Fastp: $sample"

  IN_R1="data/raw_fastq/${sample}_1.fastq.gz"
  IN_R2="data/raw_fastq/${sample}_2.fastq.gz"

  if [[ ! -f "${IN_R1}" || ! -f "${IN_R2}" ]]; then
    echo "ERROR: Missing raw FASTQ(s) for ${sample}"
    echo "  Expected: ${IN_R1}"
    echo "            ${IN_R2}"
    exit 1
  fi

  fastp \
    -i "${IN_R1}" \
    -I "${IN_R2}" \
    -o "data/interim/trimmed/${sample}_R1.fastq.gz" \
    -O "data/interim/trimmed/${sample}_R2.fastq.gz" \
    --detect_adapter_for_pe \
    --qualified_quality_phred 20 \
    --length_required 50 \
    --thread "${THREADS:-8}" \
    --html "results/qc/fastp/${sample}.html" \
    --json "results/qc/fastp/${sample}.json"
done

