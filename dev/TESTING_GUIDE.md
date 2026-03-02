# Testing Guide

## Overview

ComptoxR uses [testthat](https://testthat.r-lib.org/) for unit tests and [vcr](https://docs.ropensci.org/vcr/) for HTTP mocking. VCR records real API responses as YAML "cassettes" on first run, then replays them on subsequent runs — no network access or API key needed after recording.

## Quick Reference

```bash
# Run all tests (uses cached cassettes)
Rscript -e "devtools::test()"

# Run a single test file
Rscript -e "testthat::test_file('tests/testthat/test-ct_hazard.R')"

# Record/re-record cassettes in parallel (8 workers)
Rscript dev/rerecord_cassettes.R --all

# Re-run only the failures from last recording session
Rscript dev/rerecord_cassettes.R --failures

# Check coverage
Rscript dev/calculate_coverage.R
```

## How VCR Cassettes Work

1. **First run** — VCR intercepts the HTTP call, hits production, saves the response to `tests/testthat/fixtures/<name>.yml`
2. **Subsequent runs** — VCR intercepts the HTTP call, replays from the saved YAML file (no network)
3. **Missing cassette** — VCR makes a live API call and records it (requires API key)
4. **Existing cassette** — VCR replays it, even if it contains an error response

### Cassette Lifecycle

```
Write test with vcr::use_cassette("name", { ... })
         │
         ▼
   Cassette exists?
    ┌─ YES ──► Replay saved response (offline, fast)
    │
    └─ NO ───► Hit production API ──► Save response to fixtures/name.yml
                    │
                    ▼
              Response OK? ──► Commit cassette to git
                    │
                    NO ──► Delete cassette, fix issue, re-record
```

### Important Rules

- **Error cassettes are poison.** If a 500/404/401 gets recorded, VCR will replay that error forever. Delete the cassette and re-record when the API is stable.
- **Cassettes must be committed.** CI has no API key — it can only replay.
- **API keys are auto-filtered.** VCR config in `helper-vcr.R` replaces the real key with `<<<API_KEY>>>` in cassettes.
- **Always verify before committing** — check cassettes don't contain real API keys.

## Writing Tests

### Basic Pattern

```r
test_that("ct_hazard works with single input", {
  vcr::use_cassette("ct_hazard_single", {
    result <- ct_hazard(query = "DTXSID7020182")
    expect_s3_class(result, "tbl_df")
    expect_true(nrow(result) > 0)
  })
})
```

### Naming Conventions

- Test file: `test-<function_name>.R`
- Cassette: `<function_name>_<variant>.yml` (e.g., `ct_hazard_single`, `ct_hazard_batch`)

### Common Variants

- `_single` — one identifier input
- `_batch` — vector of multiple identifiers
- `_error` — expected error handling (invalid input, missing args)

### Gotchas

- **Check the active function signature.** Some files have multiple definitions of the same function (R uses the last one). Verify parameter names match the active definition.
- **`batch_limit = 0` functions can't batch.** Don't write batch tests for static endpoints.
- **`batch_limit = 1` functions are single GET requests.** They accept one value at a time but will iterate over a vector internally.

## Recording Cassettes

### Prerequisites

- Valid API key: `Sys.getenv("ctx_api_key")` must return a key
- The `.Renviron` file at `~/.Renviron` should contain: `ctx_api_key = 'your-key-here'`
- EPA servers must be reachable and stable

### Parallel Recording (Recommended)

`dev/rerecord_cassettes.R` uses mirai with 8 workers for parallel recording:

```bash
# Priority tests only (chemical, search, resolver)
Rscript dev/rerecord_cassettes.R

# All test files
Rscript dev/rerecord_cassettes.R --all

# Custom configuration
Rscript dev/rerecord_cassettes.R --all --workers 4 --batch-size 30

# Re-run failures from last session
Rscript dev/rerecord_cassettes.R --failures
```

Failures are logged to `dev/logs/rerecord_failures.log` for easy retry.

### Cassette Management Helpers

All helpers live in `tests/testthat/helper-vcr.R`:

```r
source("tests/testthat/helper-vcr.R")

# List all cassettes
list_cassettes()

# Delete by pattern (dry_run=TRUE by default, shows what would be deleted)
delete_cassettes("ct_hazard")
delete_cassettes("ct_hazard", dry_run = FALSE)  # actually delete

# Delete all (dry_run=TRUE by default)
delete_all_cassettes()
delete_all_cassettes(dry_run = FALSE)  # nuclear option

# Check for leaked API keys
check_cassette_safety()                    # all cassettes
check_cassette_safety("ct_hazard")         # by pattern

# Find cassettes with error responses (4xx/5xx)
check_cassette_errors()                    # report only
check_cassette_errors(delete = TRUE)       # report and delete
```

### Auditing Cassettes After Recording

After a recording session, always check for bad cassettes before committing:

```r
source("tests/testthat/helper-vcr.R")

# 1. Find any cassettes that recorded error responses
check_cassette_errors()

# 2. Delete them (they'll replay errors forever)
check_cassette_errors(delete = TRUE)

# 3. Verify no API keys leaked
check_cassette_safety()
```

### Handling Server Issues

EPA servers (`comptox.epa.gov`, `hcd.rtpnc.epa.gov`) intermittently reset connections. When this happens:

1. Don't keep retrying immediately — wait and try later
2. Cassettes that recorded error responses need to be deleted and re-recorded
3. Use `--failures` mode to retry only what failed

## CI Integration

- CI runs `devtools::test()` which replays committed cassettes (no API key needed)
- Coverage is checked via `.github/workflows/coverage-check.yml` (75% threshold, warn-only)
- `dev/` and `R/data.R` are excluded from coverage measurement

## File Layout

```
tests/
  testthat/
    helper-vcr.R            # VCR config + cassette management helpers
    fixtures/                # Recorded YAML cassettes (committed to git)
    test-*.R                 # Test files
dev/
  rerecord_cassettes.R       # Parallel cassette recording (mirai, 8 workers)
  calculate_coverage.R       # Coverage reporting
  generate_tests.R           # Auto-generate test files from metadata
  detect_test_gaps.R         # Find functions missing tests
```
