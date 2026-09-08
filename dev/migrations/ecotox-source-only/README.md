# ECOTOX source-only verification

Baseline: ComptoxR `8f055b8`, integration worktree. Decisions: migration plans
at `516dfd4`. No release or public asset changes were made by this workstream.

## Frozen evidence

`frozen-query-output.rds` contains original default and detailed query results
from the `8f055b8` query implementation and the harmonizer worker's frozen
dictionary. The fixture includes Adult, an unknown description, a missing
description, and a repeated Adult description. Missing derived values remain
missing. No provider refresh was used.

SHA256: `291f94feee5ee64ed57040e76ce9cab543b7ce1b823aff81998245ddfa85a791`.
`baseline-hashes.csv` records SHA256 for the unmodified worktree inputs.

## Checks

- Baseline: `devtools::test(filter = 'eco_functions|eco_lifestage|ecotox_vocabulary_drift|cran_tarball_test_paths')`:
  183 passes, no failures, warnings, or skips.
- Source: `devtools::test(filter = 'eco_functions|ecotox_source_only')`:
  62 passes, no failures, warnings, or skips. One further full HTTP value
  comparison was then added and passed in the installed check below.
- Installed: `R CMD INSTALL --no-multiarch --library=<isolated-library> .`:
  passed, including temporary and final location load checks. Load ComptoxR
  from this library, copy `helper-ecotox-db.R` and
  `test-ecotox_source_only.R` to a temporary directory outside the checkout,
  source the helper, and run `testthat::test_file('test-ecotox_source_only.R',
  stop_on_failure = TRUE)`: 26 passes, no failures, warnings, or skips.
- `roxygen2::roxygenise(roclets = 'rd')`: only `man/eco_results.Rd` changed.
- `rmarkdown::render('vignettes/articles/ecotox.Rmd', output_format = 'html_document')`
  and `tools::Rd2HTML('man/eco_results.Rd')`: completed. Query chunks are
  intentionally not executed during rendering. The coordinator owns final
  rendered-site review and the installed harmonization example.
- `air format` and `git diff --check`: passed.
- `jarl check` on changed R/query/build/test files: passed. The shipped server
  retains its pre-existing `ComptoxR:::.eco_get_con()` lint warning.

The host R process reports invalid inherited `C.UTF-8` locale settings at
startup, outside testthat. The builder test uses the supported Windows UTF-8
locale. Installed testthat also reports that it was built under R 4.5.3;
the test runtime was R 4.5.1.

## Gate scope

Direct queries pass with absent, present, and stale derived tables. Tests
confirm native code/description output, no derived output, duplicate-table
rows have no effect, and old tables remain unchanged. Named calls that use
the removed argument fail.

The HTTP test starts the shipped server with the matching package, uses real
localhost requests, compares all values with a direct query, and checks
missing descriptions and empty results. JSON uses named column arrays so an
empty result retains its fields. Nulls preserve missing values. This is a
breaking server/client update and requires a restart.

Both builders run the full import, Parquet conversion, enrichment, database
write, and source-only query with deterministic local input, including a new
unmapped life-stage description. Mocks replace FTP discovery/download,
archive population, and appendix reads only. Each build uses a new temporary
data directory. The installed check repeats this with the installed builder.
No user database is opened for writing.

The builders already differed in year-duration conversion before this work.
This unrelated difference was preserved.

## Coordinator gates still required

Publish and verify envharmonizer before any breaking removal release or asset
withdrawal. Remove transferred implementation/seed/domain tests only after
destination inventory and parity approval. Complete the pinned production
archive rebuild, final source-tarball contents/checks, installed cross-package
example, release workflow, and public asset withdrawal. Local test success
does not replace these release gates.
