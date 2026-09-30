#!/usr/bin/env bash
# Verify a staged wave worktree: retire superseded legacy tests, run contract/hook tests,
# and compare the installed original and wave clients on localhost.
# Usage: dev/specmill-rebuild/verify-wave.sh <wave-name>   (from the package root)
set -euo pipefail
root=$(pwd)
artifacts="$root/dev/specmill-pilot/artifacts"
work="$artifacts/wave-$1"
cd "$work"
R_LIBS="$artifacts/legacy-toolkit-library" Rscript dev/generate_tests.R --generate
R_LIBS="$artifacts/legacy-toolkit-library" Rscript dev/generate_tests.R --check
Rscript dev/generate_specmill.R --check > /dev/null
rm -rf "$artifacts/wave-$1-library" && mkdir -p "$artifacts/wave-$1-library"
R CMD INSTALL --library="$artifacts/wave-$1-library" . > "$artifacts/wave-$1-install.log" 2>&1
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(contract-.*|generic_request_edge|hooks_stage_server|chemi_search|ct_chemical_list_all_hooks|chemi_descriptor_contracts|hooks-webtest|chemi_public_options|chemi_prediction_body_shapes|explicit_request_bodies|chemi_resolver_chemical_resolution|hooks_compound|hooks_hazard|chemi_resolver_transformations|chemi_resolver_getsimilaritymap_sort|generic_chemi_request|chemi_custom_transforms|probe_api_function|exported_utility_contracts|prediction_classifier_preservation|chemi_predict|ct_related_compatibility)$", stop_on_failure=TRUE, reporter="summary")' > "$artifacts/wave-$1-tests.log" 2>&1
tail -3 "$artifacts/wave-$1-tests.log"
Rscript dev/specmill-full/verify-runtime.R "$artifacts/before-library" "$artifacts/wave-$1-library" "$artifacts/wave-$1-runtime" dev/specmill-rebuild/runtime-results.json
git status --short
