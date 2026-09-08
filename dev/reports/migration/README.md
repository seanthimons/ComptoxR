# Migration evidence

Baseline: ComptoxR `516dfd4`, implementation unchanged from `8f055b8`.
Plans: `516dfd4`. Date: 2026-09-07.

The coordinator worktree is based on `integration`, then fast-forwarded to the
agreed plans. The original checkout and its untracked `endpoint-audit.md` are
unchanged. The original harmonizer `CONTEXT.md` edit is unchanged.

`Rscript dev/migration_baseline.R` ran the endpoint plan's exact focused filter
with `COMPTOXR_CRAN_SAFE_TESTS=true`, `NOT_CRAN=false`, and no API key.
Result: 454 passed assertions, 36 skipped tests, zero failures, errors, or test
warnings. The skips require external services or installed local databases.
The process reported four pre-existing Windows locale startup warnings.

The first CSV export failed because a testthat result includes a list column.
The saved result was summarized with `Rscript dev/reports/migration/summarize.R`
after fixing the export. Tests were not repeated. The raw result remains local.
`baseline-files.csv` records tracked input MD5 hashes; `endpoint-baseline.csv`
records each test result. MD5 here identifies frozen inputs, not publication
integrity. Published asset SHA-256 values are in `database-assets-before.json`.

`Rscript dev/validate_migration_release.R` passes the source-only publication
checks (native table required, either derived table rejected) and the forced
same-source-release rebuild check. Air formatting, Jarl, and `git diff --check`
pass for the coordinator's changed R scripts.

No release has been published and no database asset has been withdrawn.
The asset inventory covers rolling and versioned ECOTOX downloads. Unrelated
assets must remain. Publish and verify envharmonizer before release or withdrawal.
