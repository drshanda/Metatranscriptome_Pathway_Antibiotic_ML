#!/usr/bin/env bash
set -euo pipefail

THREADS="${THREADS:-$(nproc)}"

mkdir -p data/interim/nonrrna

RRNA_DB=refs/sortmerna/rRNA_databases.fasta

tail -n +2 metadata/sample_table.tsv | while read sample r1 r2 cond; do
  echo "rRNA removal: $sample"

  sortmerna \
    --ref "$RRNA_DB" \
    --reads data/interim/nohost/${sample}_1.fastq.gz \
    --reads data/interim/nohost/${sample}_2.fastq.gz \
    --paired_in \
    --fastx \
    --other data/interim/nonrrna/${sample} \
    --workdir data/interim/nonrrna/work_${sample} \
    --threads "$THREADS"

  pigz data/interim/nonrrna/${sample}_fwd.fastq
  pigz data/interim/nonrrna/${sample}_rev.fastq
done
