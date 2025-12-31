#!/usr/bin/env bash
set -euo pipefail


THREADS="${THREADS:-$(nproc)}"

mkdir -p data/processed/humann

tail -n +2 metadata/sample_table.tsv | while read sample r1 r2 cond; do
  echo "HUMAnN: $sample"

  humann \
    --input data/interim/nonrrna/${sample}_fwd.fastq.gz,data/interim/nonrrna/${sample}_rev.fastq.gz \
    --output data/processed/humann/${sample} \
    --threads "$THREADS"
done
