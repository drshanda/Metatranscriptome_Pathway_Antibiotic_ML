#!/usr/bin/env bash
set -euo pipefail

mkdir -p data/interim/nohost

THREADS="${THREADS:-$(nproc)}"

MOUSE_INDEX=refs/mouse/bowtie2_index

tail -n +2 metadata/sample_table.tsv | while read sample r1 r2 cond; do
  echo "Host removal: $sample"

  bowtie2 -x "$MOUSE_INDEX" \
    -1 data/interim/trimmed/${sample}_R1.fastq.gz \
    -2 data/interim/trimmed/${sample}_R2.fastq.gz \
    --threads "$THREADS" \
    --very-sensitive \
    --un-conc-gz data/interim/nohost/${sample}_%.fastq.gz \
    -S /dev/null
done
