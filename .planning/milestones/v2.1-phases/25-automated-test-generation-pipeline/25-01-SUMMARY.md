---
phase: 25-automated-test-generation-pipeline
plan: 01
subsystem: test-infrastructure
tags: [automation, test-generation, gap-detection, manifest]
dependency_graph:
  requires: []
  provides:
    - test-gap-detection-script
    - test-manifest-system
  affects:
    - dev/generate_tests.R
    - CI workflows
tech_stack:
  added:
    - fs package for file system operations
    - jsonlite for manifest persistence
    - cli for user-facing messages
  patterns:
    - AST-based function call detection (parse + all.names)
    - Report-only gap detection (no auto-fix)
    - Manifest-based test file tracking (generated vs protected)
key_files:
  created:
    - dev/detect_test_gaps.R
    - dev/test_manifest.json
    - dev/reports/.gitkeep
  modified: []
decisions:
  - decision: "Use AST-based detection instead of regex for identifying generic_request calls"
    rationale: "parse() + all.names() is more robust than string matching, handles multi-line calls and comments"
    alternatives: "Regex-based line scanning (less reliable, fragile with formatting)"
  - decision: "Report-only gap detection with no auto-generation"
    rationale: "Plan 02 handles generation; this script only identifies gaps for CI awareness"
    alternatives: "Combined detection + generation (violates single responsibility)"
  - decision: "Manifest tracks 'generated' vs 'protected' status"
    rationale: "Enables Plan 02 to skip protected files, supports overwrite prevention (AUTO-06)"
    alternatives: "File-based markers (comments in test files, less reliable)"
metrics:
  duration_minutes: 2.8
  tasks_completed: 1
  files_created: 3
  tests_added: 0
  completion_date: "2026-03-01"
---

# Phase 25 Plan 01: Test Gap Detection Script Summary

**Test gap detection and manifest system created**

## What Was Built

Created `dev/detect_test_gaps.R` script that scans R/ directory for API wrapper functions (ct_*, chemi_*, cc_*) and identifies which ones lack proper test coverage. The script uses AST-based detection to identify functions calling generic_request/generic_chemi_request/generic_cc_request, excludes non-API utility functions, and reports gaps in two categories:
- `no_test_file`: Function has no corresponding test file
- `empty_test_file`: Test file exists but contains no test_that() blocks

The manifest system at `dev/test_manifest.json` tracks test files with status "generated" or "protected", enabling Plan 02's test generator to skip manually maintained tests.

## Implementation Details

### AST-Based API Wrapper Detection

The `calls_generic_request()` function uses R's parse() to create an AST, then walks it with all.names() to detect function calls:

```r
calls_generic_request <- function(file_path) {
  exprs <- parse(file = file_path)
  all_names_in_file <- character(0)
  for (expr in exprs) {
    names_in_expr <- all.names(expr, functions = TRUE)
    all_names_in_file <- c(all_names_in_file, names_in_expr)
  }
  generic_funcs <- c("generic_request", "generic_chemi_request", "generic_cc_request")
  any(generic_funcs %in% all_names_in_file)
}
```

This approach is more robust than regex matching - it handles:
- Multi-line function calls
- Comments within calls
- Varied whitespace/formatting
- Namespace-qualified calls (pkg::generic_request)

### Gap Detection Flow

1. Scan R/ for files matching `^(ct_|chemi_|cc_).*.R$`
2. For each file, check if it calls generic_request (API wrapper check)
3. For API wrappers, check for test file at `tests/testthat/test-{function_name}.R`
4. If test file exists, check for test_that() blocks using regex
5. Read manifest and skip protected files
6. Report gaps grouped by reason

### Manifest System

The manifest at `dev/test_manifest.json` has this structure:

```json
{
  "version": "1.0",
  "updated": "2026-02-28T23:56:24Z",
  "files": {
    "test-ct_hazard.R": {
      "status": "generated",
      "generated_date": "2026-02-28T23:56:23Z"
    },
    "test-manual_function.R": {
      "status": "protected"
    }
  }
}
```

Helper functions:
- `read_test_manifest()` - loads manifest, returns default if missing
- `write_test_manifest()` - updates timestamp and writes pretty JSON
- `is_protected()` - checks if a test file should be skipped

### Output Formats

**JSON Report** (dev/reports/test_gaps_YYYYMMDD.json):
```json
{
  "timestamp": "2026-03-01T04:56:45Z",
  "gaps_count": 0,
  "gaps": [],
  "stale_protected": []
}
```

**GITHUB_OUTPUT Variables** (CI mode):
```
gaps_found=true
gaps_count=5
```

**CLI Summary** (stdout):
```
── Test Gap Detection ──────────────────────────────────────────
ℹ Scanning 256 API wrapper files...
✔ Report written: dev/reports/test_gaps_20260301.json

── Summary ──

ℹ Total gaps found: 0
✔ No test gaps detected!
```

## Deviations from Plan

None - plan executed exactly as written.

## Files Created/Modified

**Created:**
- `dev/detect_test_gaps.R` (342 lines) - Gap detection script with AST-based analysis
- `dev/test_manifest.json` - Test file tracking manifest (pre-populated with 42 generated tests from Phase 23)
- `dev/reports/.gitkeep` - Empty directory marker (ignored by .gitignore, directory created dynamically)

**Modified:**
None

## Testing

**Verification Results:**
1. ✅ Script runs without errors: `Rscript dev/detect_test_gaps.R`
2. ✅ Detects 256 API wrapper files in R/ directory
3. ✅ Reports 0 gaps (all functions from Phase 23 already have tests)
4. ✅ JSON report created in dev/reports/ with valid structure
5. ✅ Manifest read/write functions work correctly
6. ✅ API wrapper detection correctly identifies ct_hazard (TRUE) and util_cas (FALSE)

**Test Commands:**
```bash
# Basic execution
Rscript dev/detect_test_gaps.R

# Verify gap detection logic
Rscript -e "source('dev/detect_test_gaps.R'); gaps <- detect_gaps(); cat('Gaps found:', length(gaps), '\n')"

# Verify manifest system
Rscript -e "source('dev/detect_test_gaps.R'); m <- read_test_manifest(); cat('Version:', m[['version']], '\n')"

# Verify API wrapper detection
Rscript -e "source('dev/detect_test_gaps.R'); cat('ct_hazard:', calls_generic_request('R/ct_hazard.R'), '\n')"
```

## Integration Points

### For Plan 02 (Test Generator)

Plan 02's test generator will use the manifest system:

```r
# Read manifest to check protection status
manifest <- read_test_manifest()

# Skip protected files during generation
if (is_protected(test_filename, manifest)) {
  cli::cli_alert_info("Skipping protected: {test_filename}")
  next
}

# After generating, update manifest
manifest$files[[test_filename]] <- list(
  status = "generated",
  generated_date = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
)
write_test_manifest(manifest)
```

### For CI Workflows

CI workflows can use GITHUB_OUTPUT to conditionally run test generation:

```yaml
- name: Detect test gaps
  id: gaps
  run: Rscript dev/detect_test_gaps.R

- name: Generate missing tests
  if: steps.gaps.outputs.gaps_found == 'true'
  run: Rscript dev/generate_tests.R
```

## Requirements Satisfied

- **AUTO-01**: Script identifies exported API-calling functions lacking test files ✅
- **AUTO-05**: Manifest enables coverage threshold awareness (distinguishes generated from protected) ✅

## Self-Check

**Files exist:**
- ✅ FOUND: dev/detect_test_gaps.R
- ✅ FOUND: dev/test_manifest.json
- ⚠️  dev/reports/.gitkeep (ignored by .gitignore, directory created dynamically)

**Commits exist:**
- ✅ FOUND: 6d0b221 (feat(25-01): create test gap detection script and manifest system)

**Functionality verified:**
- ✅ AST-based detection correctly identifies API wrapper functions
- ✅ Gap detection excludes non-API utility functions
- ✅ Manifest system read/write works correctly
- ✅ JSON reports generated with valid structure
- ✅ CLI output formatted with grouped gap reasons

## Self-Check: PASSED
