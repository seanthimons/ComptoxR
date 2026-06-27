# Testing Guide

## Overview

ComptoxR has three test lanes:

- CRAN-safe unit/contract tests are the default release lane. They must not require a real `ctx_api_key`, live network access, local database downloads, or cassette recording.
- Replay/fixture integration tests use committed fixtures only. They may replay existing VCR cassettes, but they must not record new live responses.
- Live recording tests are explicit opt-in only. They require a real `ctx_api_key` and must run through isolated recording scripts or the manual Record VCR Cassettes workflow.

`COMPTOXR_CRAN_SAFE_TESTS=true` forces the CRAN-safe lane. A CRAN-like environment where `NOT_CRAN` is not `true` is also treated as CRAN-safe by the test helpers. Tests that need external services should call `skip_if_offline()`, `skip_if_no_key()`, or `skip_if_cran_safe_external()` instead of assuming network, credentials, or local databases are available.

The canonical inventory is `dev/reports/unit_test_readiness_audit.json`, validated with:

```bash
Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps
```

Use `--output <temp-path-outside-repo>` when validating documentation-only changes without regenerating the canonical report.
`dev/vcr_test_classification.json` is the VCR classification gate. Every current test file containing `vcr::use_cassette()` must be classified there, and stale classifications fail the readiness audit. The current classification set is empty because the current branch has no VCR test files.

`dev/test_manifest.json` is retired and should be absent. It is not used for readiness counts, generated-test authority, or gap suppression.

## Quick Commands

```bash
# Regenerate offline generated wrapper contract tests
Rscript dev/generate_tests.R --generate
Rscript dev/generate_tests.R --check
Rscript dev/generate_tests.R --dry-run

# Regenerate the read-only readiness audit
Rscript dev/unit_test_readiness_audit.R
Rscript dev/unit_test_readiness_audit.R --check-exports
Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps

# Run targeted tests
Rscript -e "testthat::test_file('tests/testthat/test-generic_request.R')"
Rscript -e "devtools::test(filter = 'generic_request')"

# Run the CRAN-safe readiness lane when the change has broad impact
Rscript dev/cran_readiness.R

# Run the whole package test suite only when the change has broad package impact
Rscript -e "devtools::test()"

# Record cassettes intentionally from live APIs
Rscript dev/rerecord_cassettes.R --record-live --all
Rscript dev/rerecord_cassettes.R --record-live --failures
```

## Generated Wrapper Tests

`dev/generate_tests.R` is the only active generated-test entrypoint. It builds offline mocked contract tests from exported wrapper functions in `R/*.R` and `NAMESPACE`.

Generated tests:

- call exported wrapper functions directly
- mock shared request helpers
- assert request metadata such as helper, endpoint, method, query, body, and options where available
- preserve handwritten test files by default
- remove retired generated files that have the old metadata-generator header

Generated tests must not use `vcr::use_cassette()` and must not call backticked hyphenated endpoint names.

## Wrapper Test Rubric

Default API-wrapper coverage is CRAN-safe generated contract testing. Generated wrapper tests call exported R functions
directly; they must not call endpoint slugs or backticked generated names.

Minimum generated-contract assertions:

- the wrapper crosses the expected shared helper boundary, such as `generic_request()` or service-specific helpers
- the expected endpoint or path and HTTP method are passed to the helper
- query and body parameters are mapped from wrapper arguments, including omitted or defaulted parameters when relevant
- relevant options, server selection, and API-key behavior are passed through or intentionally absent
- the mocked helper return value is passed through unchanged unless the wrapper owns response shaping

Handwritten CRAN-safe wrapper tests are reserved for behavior the generator cannot model: preprocessing, branching,
validation, pagination, error behavior, or response shaping. They should still use mocks or deterministic local fixtures
by default.

Replay/fixture wrapper tests are integration tests that replay committed fixtures only. Any test file using
`vcr::use_cassette()` must be classified in `dev/vcr_test_classification.json`.

Live or recording wrapper tests require explicit opt-in, a real `ctx_api_key`, and `--record-live`. They are not default
readiness evidence.

Export exclusions are recorded in `dev/export_test_exclusions.json`. Each exclusion must include `export`, `reason`,
`owner`, and `issue`.

## Handwritten Tests

Use handwritten tests for behavior outside the generator model:

- shared request helpers and pagination
- data cleanup and binding utilities
- local database behavior for DSS, ECOTOX, and ToxVal
- GenRA math, validation, printing, and offline workflow edge cases
- lifestage curation gates and data integrity
- generator and audit tooling

Delete or replace handwritten VCR tests that only duplicate ordinary wrapper request-contract coverage.

## VCR Policy

VCR cassettes live under `tests/testthat/fixtures/` and are for replay/fixture integration. Existing cassettes should be used for targeted validation when they are present and relevant. Missing cassettes must not cause CI or routine local tests to hit production APIs or auto-record responses.

Live recording is manual and isolated:

- Use the Record VCR Cassettes workflow, or
- Run `Rscript dev/rerecord_cassettes.R --record-live`.

Recording requires a real `ctx_api_key`; placeholder, empty, dummy, or redacted-looking keys fail preflight. Never write real credentials into tests, fixtures, logs, examples, or docs.

Before accepting cassette changes:

```r
source("tests/testthat/helper-vcr.R")
check_cassette_errors()
check_cassette_safety()
```

Any test file using `vcr::use_cassette()` must have an entry in `dev/vcr_test_classification.json` with an allowed tier such as `replay_fixture_integration`, `live_only`, or `recorder_only`.

## File Layout

```text
tests/
  README.md                         # Concise test entrypoint
  testthat/
    helper-api.R                    # Shared API test helpers
    helper-generated-contracts.R    # Generated-test mocks
    helper-vcr.R                    # VCR config and cassette safety helpers
    setup.R                         # Test environment defaults
    fixtures/                       # Recorded YAML cassettes
    test-*.R                        # Generated and handwritten tests
dev/
  generate_tests.R                  # Active generated-test entrypoint
  test_generation/                  # Generator modules
  unit_test_readiness_audit.R       # Canonical readiness inventory
  reports/unit_test_readiness_audit.json # Canonical readiness report
  vcr_test_classification.json      # VCR test classification gate
  export_test_exclusions.json       # Intentional export-gap exclusions
  detect_test_gaps.R                # Legacy gap scan without manifest authority
  rerecord_cassettes.R              # Explicit live cassette recording
```
