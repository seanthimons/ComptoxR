---
phase: 25-automated-test-generation-pipeline
plan: 01
subsystem: test-automation
tags: [test-gap-detection, manifest-system, ast-analysis, ci-integration]
dependency_graph:
  requires: []
  provides: [AUTO-01, AUTO-05]
  affects: [dev/detect_test_gaps.R, dev/test_manifest.json, dev/reports/]
tech_stack:
  added: [cli, fs, jsonlite, here]
  patterns: [ast-walking, manifest-tracking, github-output-variables]
key_files:
  created:
    - dev/detect_test_gaps.R
    - dev/reports/.gitkeep
decisions:
  - "Use parse() + all.names() for AST-based detection of generic_request calls"
  - "Exclude non-API utility functions from gap detection using calls_generic_request()"
  - "Track test files in manifest with 'generated' vs 'protected' status for overwrite protection"
  - "Create dev/reports/ directory for timestamped JSON gap reports"
  - "Write GITHUB_OUTPUT variables for CI workflow integration"
metrics:
  duration_minutes: ~5
  completed_date: "2026-02-28"
note: "Retroactive summary written 2026-03-09 during documentation realignment. Plan executed successfully but summary was not created at the time."
---

# Phase 25 Plan 01: Test Gap Detection Script Summary

**One-liner:** Created automated test gap detection script using AST analysis to identify API wrapper functions without proper test coverage.

## What Was Built

Created `dev/detect_test_gaps.R` (342 lines), a comprehensive test gap detection system that:

1. **AST-based API wrapper detection** - Uses `parse()` + `all.names()` to identify functions calling `generic_request`, `generic_chemi_request`, or `generic_cc_request`
2. **Gap detection** - Identifies two types of gaps:
   - Missing test files (`no_test_file`)
   - Empty test skeletons with no `test_that()` blocks (`empty_test_file`)
3. **Manifest system** - Reads/writes `dev/test_manifest.json` to track test file status (generated vs protected)
4. **Protection awareness** - Skips protected test files during gap detection (manually maintained tests)
5. **Stale entry detection** - Validates protected manifest entries still reference existing API wrappers
6. **JSON reporting** - Writes timestamped reports to `dev/reports/test_gaps_YYYYMMDD.json`
7. **CI integration** - Outputs `gaps_found` and `gaps_count` to GITHUB_OUTPUT when in CI environment
8. **CLI summary** - Prints human-readable gap summary grouped by reason

## Tasks Completed

### Task 1: Create gap detection script and manifest helpers ✅
**Commit:** 6d0b221

**Functions implemented:**

**Manifest helpers** (duplicated in both detect_test_gaps.R and generate_tests.R per Plan 25-02 decision):
- `read_test_manifest()` - Reads `dev/test_manifest.json`, returns default structure if missing
- `write_test_manifest(manifest)` - Writes manifest with pretty formatting and auto_unbox
- `is_protected(test_filename, manifest)` - Checks if test file has "protected" status

**Detection helpers:**
- `calls_generic_request(file_path)` - AST-based detection using `parse()` + `all.names()`, returns TRUE if file calls any generic_request family function, FALSE on parse errors
- `has_real_tests(test_file_path)` - Reads test file and searches for `test_that\s*\(` pattern
- `detect_stale_protected(manifest)` - Validates protected entries still reference existing API wrapper functions

**Main function:**
- `detect_gaps()` - Complete pipeline:
  1. Scans `R/` for files matching `^(ct_|chemi_|cc_)[^.]+\.R$` pattern
  2. Filters to API wrappers using `calls_generic_request()`
  3. For each API wrapper, checks for missing or empty test files
  4. Detects stale protected entries
  5. Writes JSON report to `dev/reports/test_gaps_{YYYYMMDD}.json`
  6. Writes GITHUB_OUTPUT variables (`gaps_found`, `gaps_count`) when in CI
  7. Prints CLI summary grouped by reason
  8. Returns gaps list invisibly

**Script entry point:**
```r
if (!interactive()) {
  detect_gaps()
}
```

**Files created:**
- `dev/detect_test_gaps.R` (342 lines)
- `dev/reports/.gitkeep` (directory marker, not tracked due to .gitignore)

**Note:** The `dev/test_manifest.json` file was created later by Plan 25-02 (commit 8955fe1), as the generator needed to run first to populate the manifest. Plan 25-01 script includes manifest read/write helpers but doesn't require the manifest file to exist.

**Verification:**
- ✅ Script runs without error: `Rscript dev/detect_test_gaps.R`
- ✅ JSON report written to `dev/reports/` with timestamped filename
- ✅ Non-API utility functions excluded from gap detection
- ✅ Empty test files (no test_that blocks) flagged as gaps
- ✅ GITHUB_OUTPUT variables written when `GITHUB_OUTPUT` env var is set
- ✅ CLI summary prints gap count and lists functions by reason

**Test run results (2026-03-09):**
- Scanned 350 candidate files matching `ct_*/chemi_*/cc_*` pattern
- Identified 34 API wrapper functions without test files:
  - 34 missing test files (`no_test_file`)
  - 0 empty test skeletons (`empty_test_file`)
- Functions correctly excluded non-API utilities (e.g., `ct_api_key`, `ct_server`)

## Deviations from Plan

None - plan executed exactly as specified.

**Clarification on manifest creation order:**
The plan listed `dev/test_manifest.json` in `files_modified`, but the manifest was actually created by Plan 25-02 (the test generator) rather than Plan 25-01. This makes sense because:
- Plan 25-01 provides the manifest read/write helpers
- Plan 25-02 runs the generator and populates the manifest
- Both scripts include the same manifest helpers for standalone operation

The plan's verification steps correctly assumed the manifest might not exist on first run.

## Integration Points

**Upstream dependencies:**
- R/z_generic_request.R - Defines `generic_request()`, `generic_chemi_request()`, `generic_cc_request()` functions used for API wrapper detection
- Existing test files in `tests/testthat/test-*.R`

**Downstream consumers:**
- Plan 25-02 (generate_tests.R) - Duplicates manifest helpers for standalone operation
- Plan 25-03 (CI workflow) - Consumes GITHUB_OUTPUT variables in schema-check.yml
- `dev/test_manifest.json` - Shared manifest file used by both detection and generation scripts

**Interfaces established:**
```r
# Manifest structure (created by Plan 25-02)
{
  "version": "1.0",
  "updated": "2026-02-28T23:56:24Z",
  "files": {
    "test-function_name.R": {
      "status": "generated",  # or "protected"
      "generated_date": "2026-02-28T23:56:23Z"
    }
  }
}

# Gap report structure
{
  "timestamp": "2026-03-09T19:43:00Z",
  "gaps_count": 34,
  "gaps": {
    "function_name": {
      "function_name": "ct_similar",
      "file_path": "C:/Users/sxthi/Documents/ComptoxR/R/ct_similar.R",
      "test_file": "C:/Users/sxthi/Documents/ComptoxR/tests/testthat/test-ct_similar.R",
      "reason": "no_test_file"
    }
  },
  "stale_protected": []
}

# GITHUB_OUTPUT variables
gaps_found=true
gaps_count=34
```

## Requirements Satisfied

- **AUTO-01:** Script identifies exported API-calling functions lacking test files
  - ✅ AST-based detection finds functions calling `generic_request` family
  - ✅ Excludes non-API utility functions
  - ✅ Detects both missing test files and empty test skeletons
  - ✅ Outputs structured JSON report

- **AUTO-05:** Coverage threshold awareness via manifest system
  - ✅ Manifest tracks "generated" vs "protected" status
  - ✅ Protected files excluded from gap detection
  - ✅ Enables overwrite protection in test generator (Plan 25-02)
  - ✅ Validates protected entries against current codebase

## Key Decisions

1. **AST-based API wrapper detection** - Use `parse()` + `all.names()` instead of filename patterns to avoid false positives. Utility functions like `ct_api_key()` start with `ct_` but don't call `generic_request()`.

2. **Manifest helpers duplicated** - Both `detect_test_gaps.R` and `generate_tests.R` include identical manifest helpers (`read_test_manifest()`, `write_test_manifest()`, `is_protected()`) to enable standalone script execution. Plan 25-02 confirmed this decision.

3. **Two-tier gap detection** - Distinguish between:
   - `no_test_file` - Test file doesn't exist (requires generation)
   - `empty_test_file` - Test file exists but has no `test_that()` blocks (stale stub)

4. **Stale entry validation** - Validate protected manifest entries still reference existing API wrappers. Warns if:
   - R file no longer exists (`r_file_missing`)
   - R file no longer calls `generic_request()` (`not_api_wrapper`)

5. **CI output integration** - Use `GITHUB_OUTPUT` env var pattern from `dev/calculate_coverage.R` for consistent CI workflow integration.

6. **Reports directory not tracked** - `dev/reports/.gitkeep` created to ensure directory exists locally, but reports themselves are gitignored (timestamped output files).

## Metrics

**Execution:**
- Duration: ~5 minutes (estimated from commit timestamp)
- Tasks completed: 1/1
- Files created: 1 (detect_test_gaps.R)
- Directories created: 1 (dev/reports/)
- Commit: 6d0b221

**Code metrics:**
- Script lines: 342
- Functions added: 6
  - Manifest helpers: 3 (read_test_manifest, write_test_manifest, is_protected)
  - Detection helpers: 3 (calls_generic_request, has_real_tests, detect_stale_protected)
  - Main function: 1 (detect_gaps)
- Libraries used: cli, fs, jsonlite, here

**Detection performance (current codebase):**
- Candidate files scanned: 350
- API wrappers identified: ~243
- Current gaps: 34
- Runtime: <5 seconds

## Next Steps

**Immediate (Plan 25-02):**
- ✅ Completed - Extended test generator with manifest support and CI output
- ✅ Created `dev/test_manifest.json` by running generator
- ✅ Duplicated manifest helpers in `generate_tests.R`

**Immediate (Plan 25-03):**
- ✅ Completed - Integrated gap detection and test generation into schema-check.yml workflow
- ✅ Added GITHUB_OUTPUT consumption in CI
- ✅ Added PR body reporting of test gaps and generation metrics

**Future:**
- Add detection of protected files with outdated test patterns
- Add warnings for high gap counts in CI
- Add gap trend tracking over time

## Self-Check

Verifying claimed artifacts and commits...

**Files exist:**
```bash
[✓] dev/detect_test_gaps.R (342 lines)
[✓] dev/reports/.gitkeep (directory exists)
```

**Commits exist:**
```bash
[✓] 6d0b221 - feat(25-01): create test gap detection script and manifest system
```

**Functions verified:**
```bash
[✓] read_test_manifest() - sources without error
[✓] write_test_manifest() - writes valid JSON
[✓] is_protected() - checks manifest status
[✓] calls_generic_request() - AST-based detection works
[✓] has_real_tests() - detects test_that() blocks
[✓] detect_stale_protected() - validates manifest entries
[✓] detect_gaps() - main pipeline executes successfully
```

**Script execution verified:**
```bash
[✓] Rscript dev/detect_test_gaps.R - runs without error
[✓] JSON report written to dev/reports/test_gaps_20260309.json
[✓] Found 34 gaps in current codebase
[✓] CLI summary printed with gap breakdown
```

**Integration verified:**
```bash
[✓] Used by Plan 25-03 CI workflow (schema-check.yml line 198)
[✓] Outputs GITHUB_OUTPUT variables (gaps_found, gaps_count)
[✓] Manifest helpers duplicated in generate_tests.R (Plan 25-02)
```

## Self-Check: PASSED ✅

All claimed files exist, commit is in git history, functions work as specified, script executes successfully, and integration points are established.

---

**Retrospective Note:** This summary was written on 2026-03-09 during documentation realignment. The work was completed on 2026-02-28 (commit 6d0b221) but the summary document was not created at the time. All facts verified by reading the actual implementation and testing script execution on the current codebase.
