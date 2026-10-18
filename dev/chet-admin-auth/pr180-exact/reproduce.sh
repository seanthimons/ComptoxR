#!/usr/bin/env bash
set -euo pipefail
# Run from the ComptoxR root. All tooling and generated projects stay private.
PR180_CACHE="${PR180_CACHE:-$HOME/.cache/comptoxr-pr180-exact-test}"
export PR180_CACHE
export TMPDIR="$PR180_CACHE/tmp"
mkdir -p "$TMPDIR" "$PR180_CACHE/library"
sha=d9c6f9600f075e941999fc4fafffd4ede3d90b73
archive="$PR180_CACHE/source.tar.gz"
if [[ ! -f "$archive" ]]; then
  gh api "repos/seanthimons/specmill/tarball/$sha" > "$archive"
fi
printf '%s  %s\n' 9ac0233be83cef396e847906567d95a56c14061172f3a32ef3ae95cb22fc5f59 "$archive" | sha256sum --check
test "$(gh api "repos/seanthimons/specmill/commits/$sha" --jq .sha)" = "$sha"
tar -xzf "$archive" -C "$PR180_CACHE"
source_dir="$PR180_CACHE/seanthimons-specmill-d9c6f96"
R CMD INSTALL --library="$PR180_CACHE/library" "$source_dir" > "$PR180_CACHE/install.log" 2>&1
python3 dev/chet-admin-auth/pr180-exact/provenance.py
Rscript dev/chet-admin-auth/pr180-exact/replay.R > "$PR180_CACHE/replay.log" 2>&1
R_LIBS="$PR180_CACHE/library" Rscript "$source_dir/tests/free-form-fields.R" > "$PR180_CACHE/upstream-free-form.log" 2>&1
cat "$PR180_CACHE/replay.log" "$PR180_CACHE/upstream-free-form.log"
