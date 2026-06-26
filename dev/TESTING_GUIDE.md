# Testing Guide

## Overview

ComptoxR has two test lanes:

- Offline unit and generated contract tests, which are the default and must not require live services, API keys, downloads, or cassette recording.
- Explicit integration recording, which may call live APIs and update VCR cassettes only when requested.

The canonical inventory is `dev/reports/unit_test_readiness_audit.json`, regenerated with:

```bash
Rscript dev/unit_test_readiness_audit.R
```

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

# Run targeted tests
Rscript -e "testthat::test_file('tests/testthat/test-generic_request.R')"
Rscript -e "devtools::test(filter = 'generic_request')"

# Run the whole test suite when the change has broad impact
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

VCR cassettes live under `tests/testthat/fixtures/` and are for integration replay. Existing cassettes should be used for targeted validation when they are present and relevant. Do not re-record cassettes unless the task explicitly requires live recording.

Before accepting cassette changes:

```r
source("tests/testthat/helper-vcr.R")
check_cassette_errors()
check_cassette_safety()
```

Recording requires a real `ctx_api_key`; placeholder, empty, dummy, or redacted-looking keys fail preflight. Never write real credentials into tests, fixtures, logs, examples, or docs.

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
  export_test_exclusions.json       # Intentional export-gap exclusions
  detect_test_gaps.R                # Legacy gap scan without manifest authority
  rerecord_cassettes.R              # Explicit live cassette recording
```
