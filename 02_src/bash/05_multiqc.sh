#!/usr/bin/env bash
set -euo pipefail

multiqc results/qc data/processed/humann -o results/qc
