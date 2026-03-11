---
phase: 18-reliability
plan: 01
subsystem: reliability
tags: [schema-download, timeout-protection, ci-resilience, error-handling]
dependency_graph:
  requires: [17-02]
  provides: [timeout-protected-downloads, resilient-ci-workflow]
  affects: [schema-download-functions, ci-workflow]
tech_stack:
  added: [httr2-timeout, github-actions-continue-on-error]
  patterns: [graceful-degradation, log-level-differentiation]
key_files:
  created: []
  modified:
    - R/schema.R
    - .github/workflows/schema-check.yml
    - man/ct_schema.Rd
    - man/chemi_schema.Rd
    - man/cc_schema.Rd
decisions:
  - slug: timeout-default-30s
    summary: "Default timeout of 30s for R functions, 60s for CI (CI runners slower)"
    rationale: "Balances responsiveness with tolerance for network latency"
  - slug: silent-404s-in-brute-force
    summary: "Expected 404s in chemi_schema URL discovery produce no log output"
    rationale: "Reduces noise - only actual successes and real failures are logged"
  - slug: continue-on-error-workflow
    summary: "CI workflow uses continue-on-error instead of failing on download issues"
    rationale: "Allows workflow to complete with warnings, enables downstream steps to work with partial data"
metrics:
  duration_minutes: 5
  tasks_completed: 2
  files_modified: 5
  commits: 2
  completed_date: 2026-02-12
---

# Phase 18 Plan 01: Timeout Protection and CI Resilience Summary

**One-liner:** Timeout-protected schema downloads with configurable limits and CI workflow that degrades gracefully on API failures

## What Was Built

Added comprehensive timeout protection to all schema download functions (ct_schema, chemi_schema, cc_schema) and made the CI workflow resilient to API unavailability.

**Key improvements:**
1. All schema functions now accept a `timeout` parameter (default: 30s)
2. Replaced all `download.file()` calls with httr2-based downloads using `req_timeout()`
3. Differentiated log levels: success (cli_alert_success), warnings (cli_alert_warning), silent 404s
4. CI workflow has job-level 15-minute timeout and continue-on-error on critical steps
5. Download failures produce warnings via GitHub annotations, not job failures

## Tasks Completed

### Task 1: Add configurable timeout protection to schema download functions
**Status:** Complete
**Commit:** 4ddb675

**Changes:**
- Updated `ct_schema()`: Added timeout parameter, replaced download.file with httr2 + req_timeout, specific error handlers for timeout/network/5xx
- Updated `chemi_schema()`: Added timeout parameter, updated attempt_download to use configurable timeout, added tracking for any_schemas_downloaded, warns if zero schemas across all servers
- Updated `cc_schema()`: Added timeout parameter, replaced download.file with httr2 + req_timeout
- All functions wrapped in tryCatch with specific handlers: httr2_timeout, network errors, HTTP status codes
- Expected 404s in brute-force URL discovery remain silent (no output)
- Real failures emit cli warnings with context (endpoint, server, error message)
- No functions call stop() or abort() - always continue to next item

**Verification:**
- Ran `devtools::document()` - roxygen parses successfully
- Ran `devtools::load_all()` - functions load without errors
- Checked `formals()` - all three functions have timeout parameter with default 30

### Task 2: Make CI workflow resilient to schema download failures
**Status:** Complete
**Commit:** a625e74

**Changes:**
- Added job-level `timeout-minutes: 15` to check-schemas job (prevents hung workflows)
- Download step: Added `id: download`, `continue-on-error: true`, wrapped each schema function in tryCatch with timeout=60
- Hash step: Added `continue-on-error: true`, handles empty schema directory gracefully (writes empty CSV, no abort)
- Diff step: Added `continue-on-error: true`
- Added "Workflow status summary" step with GitHub Actions annotations (::warning::) for download/diff failures
- Download failures no longer fail the job - workflow completes with warning status

**Verification:**
- Visually confirmed timeout-minutes at job level (line 15)
- Confirmed continue-on-error on download (line 75), hash (line 98), diff (line 121) steps
- Confirmed tryCatch around each schema function with timeout=60 (lines 79-93)
- Confirmed workflow status summary step with GitHub annotations (lines 194-202)

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All verification criteria from plan met:

1. **R/schema.R:** No `download.file()` calls remain - all use httr2 with req_timeout
2. **R/schema.R:** All three functions have `timeout` parameter confirmed via formals()
3. **R/schema.R:** Functions load without errors after devtools::load_all()
4. **schema-check.yml:** Has timeout-minutes (15) and continue-on-error on download/hash/diff steps
5. **schema-check.yml:** Download step uses tryCatch with timeout=60 for each function
6. **No stop() or abort():** Schema functions only emit warnings, never abort

## Implementation Notes

**httr2 timeout error handling:**
- Used specific condition class `httr2_timeout` to catch timeout errors separately from general network errors
- This allows differentiated messaging: "Timeout downloading {endpoint} ({timeout}s)" vs "Network error: {message}"

**chemi_schema brute-force silence:**
- The existing `attempt_download()` helper already returns silently on 404s (list(success=FALSE))
- The plan's concern about ping_url() emitting warnings was correct - but ping_url is only used for cim_component_info endpoint discovery, not brute-force
- Brute-force loop (lines 274-291) already produces zero output on 404s - only logs on success

**CI timeout strategy:**
- Job-level 15-minute timeout protects against unforeseen hangs
- Per-function 60s timeout in CI (vs 30s default) accounts for slower CI runners
- continue-on-error allows partial success scenarios (some APIs down, others working)

## Dependencies

**Requires:**
- Phase 17-02 (CI workflow integration) - builds on existing schema-check workflow

**Provides:**
- Timeout-protected schema downloads - prevents hung API calls
- Resilient CI workflow - completes with warnings instead of failing
- Foundation for REL-03 (structured error recovery and reporting)

**Affects:**
- All schema download workflows (local and CI)
- Future schema-dependent operations can now handle partial availability

## Files Modified

1. **R/schema.R** (127 insertions, 108 deletions)
   - ct_schema: Added timeout param, httr2 download with error handling
   - chemi_schema: Added timeout param, configurable timeout in attempt_download, any_schemas_downloaded tracking
   - cc_schema: Added timeout param, httr2 download with error handling

2. **.github/workflows/schema-check.yml** (35 insertions, 4 deletions)
   - Added job-level timeout (15 min)
   - Added continue-on-error to download/hash/diff steps
   - Added tryCatch wrapper around each schema function
   - Added workflow status summary with GitHub annotations

3. **man/*.Rd** (documentation updates from roxygen)
   - ct_schema.Rd, chemi_schema.Rd, cc_schema.Rd - added @param timeout

## Testing Strategy

**Manual verification performed:**
- Roxygen documentation generation (confirms syntax correctness)
- devtools::load_all() (confirms runtime correctness)
- formals() inspection (confirms parameter defaults)

**Future testing:**
- REL-02 will add automated tests for timeout behavior
- REL-03 will add tests for error recovery and structured reporting

## Next Steps

1. **REL-02:** Add automated tests for timeout behavior (mock slow servers, verify graceful handling)
2. **REL-03:** Structured error recovery and reporting (error context objects, retry logic)
3. **REL-04:** Rate limiting and backoff strategies (prevent API throttling)

## Self-Check: PASSED

**Created files exist:**
- .planning/phases/18-reliability/18-01-SUMMARY.md: FOUND

**Commits exist:**
- 4ddb675 (Task 1): FOUND
- a625e74 (Task 2): FOUND

**Modified files verified:**
- R/schema.R: FOUND (no download.file calls, timeout params present)
- .github/workflows/schema-check.yml: FOUND (timeout-minutes, continue-on-error present)
- man/ct_schema.Rd, man/chemi_schema.Rd, man/cc_schema.Rd: FOUND
