#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
sha256sum --check dev/specmill-pr176-proof/inputs.sha256
export PROOF_CACHE="${PROOF_CACHE:-$HOME/.cache/comptoxr-pr176-exact}"
export TMPDIR="$PROOF_CACHE/tmp"
mkdir -p "$TMPDIR" "$PROOF_CACHE/lib"
sha=a656ce446fd2f4fe28184e3cad69da02e209ef26
expected=ba5e8d3cd205cb0eba35d463db3f70394cac0b32f9629dfd5741319ce4eb104e
if [ ! -d "$PROOF_CACHE/git" ]; then git init -q "$PROOF_CACHE/git"; fi
git -C "$PROOF_CACHE/git" fetch --depth=1 https://github.com/seanthimons/specmill.git "$sha"
test "$(git -C "$PROOF_CACHE/git" rev-parse FETCH_HEAD)" = "$sha"
git -C "$PROOF_CACHE/git" archive --format=tar --output="$PROOF_CACHE/exact-source.tar" "$sha"
echo "$expected  $PROOF_CACHE/exact-source.tar" | sha256sum --check
mkdir -p "$PROOF_CACHE/source"
tar -xf "$PROOF_CACHE/exact-source.tar" -C "$PROOF_CACHE/source"
Rscript -e 'p <- file.path(Sys.getenv("PROOF_CACHE"), "source/DESCRIPTION"); d <- as.list(read.dcf(p)[1, ]); d[["Config/specmill/source-commit"]] <- "a656ce446fd2f4fe28184e3cad69da02e209ef26"; d[["Config/specmill/source-archive-sha256"]] <- "ba5e8d3cd205cb0eba35d463db3f70394cac0b32f9629dfd5741319ce4eb104e"; write.dcf(as.data.frame(d, check.names=FALSE), p)'
R CMD INSTALL --library="$PROOF_CACHE/lib" "$PROOF_CACHE/source"
R_LIBS="$PROOF_CACHE/lib" Rscript "$PROOF_CACHE/source/tests/request-throttle.R"
R_LIBS="$PROOF_CACHE/lib" Rscript "$PROOF_CACHE/source/tests/scalar-query-booleans.R"
Rscript dev/specmill-pr176-proof/verify.R
