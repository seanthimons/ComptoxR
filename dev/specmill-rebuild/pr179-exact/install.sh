#!/usr/bin/env bash
set -euo pipefail
proof_cache=${PR179_CACHE:-/home/sxthi/.cache/comptoxr-pr179}
mkdir -p "$proof_cache/tmp" "$proof_cache/library"
export TMPDIR="$proof_cache/tmp"
sha=5566da87ae5acc7a95e10eaa209dbc18a290f498
test "$(gh api "repos/seanthimons/specmill/commits/$sha" --jq .sha)" = "$sha"
gh api "repos/seanthimons/specmill/tarball/$sha" > "$proof_cache/source.tar.gz"
echo "96a72b802a7f2466ac0014fb0e86032a64944ecafaeea46eb3342cdc9e3b64fe  $proof_cache/source.tar.gz" | sha256sum --check
tar -xzf "$proof_cache/source.tar.gz" -C "$proof_cache"
R CMD INSTALL --library="$proof_cache/library" "$proof_cache/seanthimons-specmill-5566da8"
Rscript dev/specmill-rebuild/pr179-exact/generate.R
Rscript dev/specmill-rebuild/pr179-exact/run.R
Rscript dev/specmill-rebuild/pr179-exact/verify.R
