# Bounded final-root package check

Terminal result: **Status: OK; 0 errors, 0 warnings, 0 notes**. Build and check exit statuses are both 0. Optional dependency INFO remains for unavailable Suggests and a knitr declaration without included vignettes; see full logs and summary.json.

A clean persistent-disk snapshot contains only exact root R/man/inst/data/DESCRIPTION/NAMESPACE/LICENSE (1205 files). fingerprint.json records every file hash and aggregate SHA256. root-comparison.json confirms whether those bytes still match current root at completion.

Build: `R CMD build --no-build-vignettes --no-manual <snapshot>`.
Check: `R CMD check --no-manual --no-vignettes --no-tests --no-examples <tarball>`.

Optional Suggests were relaxed. Tests, examples, vignette building and PDF manual were disabled. External HTTP proxies point to closed loopback port 9; inherited credential-like environment variables were blanked. TMPDIR, snapshot, build and check all used persistent disk. Build timeout 3 minutes; check timeout 15 minutes. No schema/dev/tests/vignettes were copied. This is a bounded package snapshot check, not a full strict check or deployed-service validation. No tests or extra endpoint replay ran in this task.
