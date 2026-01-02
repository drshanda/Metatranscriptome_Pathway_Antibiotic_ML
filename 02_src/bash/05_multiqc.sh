#!/usr/bin/env bash
set -euo pipefail

multiqc results/qc results/humann -o results/qc
