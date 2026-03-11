---
phase: 24-vcr-cassette-cleanup
plan: 03
subsystem: dev-tools
tags: [vcr, testing, parallel-processing, mirai, rate-limiting]
depends_on: []
requires:
  - VCR-07
provides:
  - parallel-cassette-rerecording-script
affects:
  - tests/testthat/fixtures/ (cassette re-recording target)
tech_stack:
  added:
    - mirai (async parallel processing)
  patterns:
    - Worker pool management with mirai::daemons
    - Batched execution with configurable batch size
    - Failure logging and selective re-run
    - Priority-based test file selection
key_files:
  created:
    - dev/rerecord_cassettes.R
  modified: []
decisions:
  - "Use mirai with 8 workers for parallel cassette re-recording"
  - "Prioritize Chemical domain, chemi_search, and chemi_resolver tests"
  - "Default batch size of 20 files (20-50 range per VCR-07)"
  - "Log failures to dev/logs/rerecord_failures.log for selective re-run"
  - "Delete existing cassettes before re-recording to ensure clean state"
metrics:
  duration_minutes: 2.0
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 0
  commits: 1
  completed_date: 2026-02-27
---

# Phase 24 Plan 03: Parallel Cassette Re-recording Script Summary

**One-liner:** Created batched parallel VCR cassette re-recording script using mirai with 8 workers, supporting priority/all/failures modes and failure logging.

## What Was Built

A production-ready script (`dev/rerecord_cassettes.R`) for efficient re-recording of VCR test cassettes from CompTox production APIs after Phase 23 test fixes.

**Key capabilities:**
- **Parallel execution:** 8 mirai workers processing tests concurrently
- **Batched processing:** Default 20 files per batch (configurable via --batch-size)
- **Three execution modes:**
  - Default (priority): ct_chemical*, chemi_search, chemi_resolver tests
  - --all: All test files in tests/testthat/
  - --failures: Re-run only previously failed files
- **Failure handling:** Skip failed cassettes, log to dev/logs/rerecord_failures.log, continue execution
- **Rate limiting:** Relies on httr2's built-in exponential backoff (no custom retry logic needed)
- **Pre-flight checks:** Validates API key, mirai installation, and test directory existence

## Tasks Completed

### Task 1: Create parallel re-recording script
**Files:** dev/rerecord_cassettes.R

Created complete re-recording script with:
- Configuration section (workers, batch size, delays, directories, priority patterns)
- Command-line argument parsing (--all, --failures, --batch-size, --workers)
- Pre-flight checks (API key, mirai, test directory)
- `get_test_files(mode)` function for priority/all/failures selection
- `delete_cassettes(test_file)` to remove existing cassettes before re-recording
- `rerecord_batch()` using mirai worker pool with tryCatch error handling
- Main execution flow with cli progress reporting and failure logging

**Verification:** Script parses without syntax errors
**Commit:** 426561d

### Task 2: Verify script structure and ensure log directory exists
**Files:** dev/rerecord_cassettes.R (validation only)

Verified script contains all required components:
- ✓ daemons (mirai worker pool)
- ✓ PRIORITY_PATTERNS (priority domains)
- ✓ failures (re-run mode)
- ✓ LOG_FILE (failure logging)
- ✓ tryCatch (error handling)
- ✓ BATCH_SIZE (batched execution)

Confirmed dev/logs/ directory already exists (contains stub_generation*.log files from prior work). Log files already covered by .gitignore (*.log pattern on line 68).

**No commit needed** (verification task only)

## Deviations from Plan

None - plan executed exactly as written.

## Technical Details

### Script Architecture

```r
# Configuration
N_WORKERS <- 8                          # Parallel workers
BATCH_SIZE <- 20                        # Files per batch
BASE_DELAY <- 0.5                       # Seconds between batches

# Priority patterns (LOCKED DECISION)
PRIORITY_PATTERNS <- c(
  "^test-ct_chemical",
  "^test-chemi_search",
  "^test-chemi_resolver"
)
```

### Execution Flow

1. **Parse arguments** → Determine mode (priority/all/failures), workers, batch size
2. **Pre-flight checks** → Validate API key, mirai, test directory
3. **Get test files** → Select files based on mode
4. **For each batch:**
   - Delete existing cassettes (pattern matching on test file name)
   - Initialize mirai::daemons(n = N_WORKERS)
   - Submit mirai tasks with tryCatch error handling
   - Collect results with mirai::call_mirai()
   - Track successes/failures
   - Shutdown daemons with mirai::daemons(0)
   - Delay between batches
5. **Write failures to log** → Overwrite LOG_FILE with failed file paths
6. **Summary report** → Successes, failures, elapsed time, re-run suggestion

### Error Handling

**Per-task error handling:**
```r
mirai::mirai({
  result <- tryCatch({
    testthat::test_file(file, reporter = "minimal")
    list(file = file, success = TRUE, error = NULL)
  }, error = function(e) {
    list(file = file, success = FALSE, error = as.character(e$message))
  })
  result
}, file = file)
```

**Rate limiting:** httr2's built-in exponential backoff handles HTTP 429 responses automatically (configured in generic_request). No custom retry logic needed at the script level.

### Usage Examples

```bash
# Priority batch (default - Chemical domain focus)
Rscript dev/rerecord_cassettes.R

# All test files
Rscript dev/rerecord_cassettes.R --all

# Re-run failures only
Rscript dev/rerecord_cassettes.R --failures

# Custom configuration
Rscript dev/rerecord_cassettes.R --batch-size 30 --workers 4
```

## Verification Results

All verification criteria passed:
- ✅ dev/rerecord_cassettes.R parses without syntax errors
- ✅ Script uses mirai::daemons(n = 8) for parallel execution
- ✅ Script supports --all, --failures, and default (priority) modes
- ✅ Script logs failures to dev/logs/rerecord_failures.log
- ✅ Script prioritizes ct_chemical_*, chemi_search, chemi_resolver patterns
- ✅ dev/logs/*.log is already in .gitignore (*.log pattern line 68)

## Next Steps

**Immediate:**
- Plan 24-03 complete, ready to proceed to next plan in Phase 24

**Future usage (when API key available):**
1. Set API key: `Sys.setenv(ctx_api_key = "YOUR_KEY")`
2. Run priority batch: `Rscript dev/rerecord_cassettes.R`
3. If failures occur, re-run: `Rscript dev/rerecord_cassettes.R --failures`
4. Optionally re-record all: `Rscript dev/rerecord_cassettes.R --all`

**Dependencies:**
- Requires valid ctx_api_key environment variable (request via ccte_api@epa.gov)
- Requires mirai package installation
- Works with Phase 23 fixed test files

## Self-Check: PASSED

**Created files exist:**
```bash
FOUND: dev/rerecord_cassettes.R
```

**Commits exist:**
```bash
FOUND: 426561d (feat(24-03): create parallel VCR cassette re-recording script)
```

**Log directory:**
```bash
FOUND: dev/logs/ (pre-existing, contains stub_generation logs)
```

All claimed artifacts verified successfully.
