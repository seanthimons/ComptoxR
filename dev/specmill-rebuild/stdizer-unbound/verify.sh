#!/usr/bin/env bash
set -euo pipefail
export TMPDIR=/home/sxthi/.cache/comptoxr-stdizer-unbound/tmp
mkdir -p "$TMPDIR"
export COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false
Rscript dev/specmill-rebuild/stdizer-unbound/verify-candidate.R
Rscript dev/specmill-rebuild/stdizer-unbound/verify-held.R
Rscript dev/specmill-rebuild/stdizer-unbound/generate.R
Rscript dev/specmill-rebuild/stdizer-unbound/verify-full.R
Rscript dev/specmill-rebuild/stdizer-unbound/verify.R
Rscript dev/generate_tests.R --check
python3 dev/specmill-rebuild/stdizer-unbound/verify-preserved.py
