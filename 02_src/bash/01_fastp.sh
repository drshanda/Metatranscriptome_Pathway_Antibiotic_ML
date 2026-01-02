#!/usr/bin/env bash
set -euo pipefail

mkdir -p data/interim/trimmed results/qc/fastp

tail -n +2 metadata/sample_table.tsv | while read sample r1 r2 cond; do
  echo "Fastp: $sample"

  fastp \
    -i "$r1" \
    -I "$r2" \
    -o data/interim/trimmed/${sample}_R1.fastq.gz \
    -O data/interim/trimmed/${sample}_R2.fastq.gz \
    --detect_adapter_for_pe \
    --qualified_quality_phred 20 \
    --length_required 50 \
    --thread "${THREADS:-8}" \
    --html results/qc/fastp/${sample}.html \
    --json results/qc/fastp/${sample}.json
done
