## Test Environments

* Local: Windows 11 x64, R 4.5.1 (2025-06-13 ucrt), x86_64-w64-mingw32
* GitHub Actions: ubuntu-latest, R release, pending final R-CMD-check run URL
* GitHub Actions: windows-latest, R release, pending final R-CMD-check run URL
* GitHub Actions: macos-latest, R release, pending final R-CMD-check run URL

## R CMD Check Results

0 errors | 0 warnings | 2 notes

Expected CRAN note:

* This is a new submission.

Local environment note:

* The local Windows `R CMD check --as-cran` run also reported `unable to verify current time` under future file
  timestamps. This is an environment clock-verification limitation, not a package timestamp issue; tarball contents were
  inspected separately.

## CRAN-Safe Test Scope

The package includes wrappers for external EPA, PubChem, ClassyFire, and database-backed resources. CRAN-safe tests do
not require a real `ctx_api_key`, live network access, cassette recording, or local DuckDB database downloads.

External-service and local-database tests are skipped on CRAN-like runs unless their required opt-in credentials,
fixtures, or local resources are present. The release readiness lane validates that generated wrapper contract tests are
current, every exported function is covered or explicitly excluded, and committed cassette fixtures contain no unsafe
secrets, HTTP error cassettes, or YAML parse errors.

## Additional Release Checks

* `urlchecker::url_check()` passes for 312 URLs.
* `spelling::spell_check_package()` reports no spelling errors after accepted project/domain terms were added to
  `inst/WORDLIST`.
* `Rscript dev/generate_tests.R --check` passes.
* `Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps` reports 386 function exports and 0 export
  gaps after documented exclusions.
* `Rscript dev/check_cassette_health.R` reports 0 cassettes, 0 safety issues, 0 HTTP error responses, and 0 parse
  errors.
* `Rscript dev/cran_readiness.R` passes in CRAN-safe mode without a real `ctx_api_key`.
* `R CMD build . --no-resave-data` builds `ComptoxR_1.5.0.tar.gz`.
* `R CMD check --as-cran ComptoxR_1.5.0.tar.gz` passes locally with 0 errors, 0 warnings, and the two notes listed
  above.
* Source tarball review found no local-only `.github`, `.planning`, `dev`, `schema`, `data-raw`, `cran-comments.md`, log,
  check, or scratch paths across 1,156 tarball entries.
