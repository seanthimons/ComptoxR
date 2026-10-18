#!/usr/bin/env bash
set -euo pipefail
proof_cache=${PR179_CACHE:-/home/sxthi/.cache/comptoxr-specmill-finish}
mkdir -p "$proof_cache/tmp" "$proof_cache/library"
export TMPDIR="$proof_cache/tmp"
sha=1c3e8a34c41eba5d2a20cc46f8bc2e39abb6d18c
test "$(gh api "repos/seanthimons/specmill/commits/$sha" --jq .sha)" = "$sha"
gh api "repos/seanthimons/specmill/tarball/$sha" > "$proof_cache/source.tar.gz"
echo "3f494caf0842915624d5ba79aa4f9d3583c7e82d3392ac77f0efcf4e05b8c1ee  $proof_cache/source.tar.gz" | sha256sum --check
tar -xzf "$proof_cache/source.tar.gz" -C "$proof_cache"
R CMD INSTALL --library="$proof_cache/library" "$proof_cache/seanthimons-specmill-1c3e8a3"
Rscript dev/specmill-rebuild/pr179-finish-1c3e8a3/generate.R
Rscript dev/specmill-rebuild/pr179-finish-1c3e8a3/run.R
Rscript dev/specmill-rebuild/pr179-finish-1c3e8a3/verify.R
R_LIBS="$proof_cache/library" Rscript "$proof_cache/seanthimons-specmill-1c3e8a3/tests/request-pagination.R"
