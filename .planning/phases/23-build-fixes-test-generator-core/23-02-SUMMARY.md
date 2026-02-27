---
phase: 23-build-fixes-test-generator-core
plan: 02
subsystem: dev-tools
tags: [build-fixes, stub-generator, schema-automation, testing]
dependency_graph:
  requires: [23-01]
  provides: [stub-syntax-fix, schema-alignment, drift-detection]
  affects: [dev/endpoint_eval/*, dev/generate_stubs.R, dev/diff_schemas.R, .github/workflows/schema-check.yml]
tech_stack:
  added: []
  patterns: [parse-validation, parameter-extraction, drift-reporting]
key_files:
  created:
    - dev/endpoint_eval/08_drift_detection.R
    - tests/testthat/test-stub-generator.R
    - tests/testthat/test-drift-detection.R
  modified:
    - dev/endpoint_eval/07_stub_generation.R
    - dev/endpoint_eval/01_schema_resolution.R
    - dev/generate_stubs.R
    - dev/diff_schemas.R
    - .github/workflows/schema-check.yml
decisions:
  - Remove ALL default values when extracting parameter names (not just = NULL)
  - Add parse() validation at stub generation time to catch syntax errors early
  - Use Approach A for schema selection alignment (shared select_schema_files)
  - Drift detection is report-only (no auto-modification of existing functions)
  - Framework parameters (tidy, verbose, ..., all_pages) excluded from drift reports
metrics:
  duration: 6.7 minutes
  tasks_completed: 2
  files_modified: 8
  test_files_created: 2
  tests_added: 32
  commits: 2
  completed_date: 2026-02-27
---

# Phase 23 Plan 02: Fix Generator Pipeline Core Summary

**One-liner:** Fixed stub generator syntax bugs (BUILD-01, BUILD-06) and implemented schema alignment + drift detection for automated schema updates.

## Tasks Completed

### Task 1: Fix stub generator syntax bugs and roxygen mismatch (BUILD-01, BUILD-06)

**BUILD-01 Fix: Invalid syntax generation**
- **Root cause:** When extracting parameter names from function signatures, code only removed ` = NULL` but not other default values like ` = "RF"`
- **Impact:** Generated invalid syntax: `if (!is.null(model = "RF")) options$model = "RF" <- model = "RF"`
- **Fix:** Updated regex to remove ALL defaults: `gsub("\\s*=\\s*.*$", "", param_vec)`
- **Locations fixed:**
  - `07_stub_generation.R` lines 693-710 (generic_chemi_request)
  - `07_stub_generation.R` lines 773-790 (generic_request)

**BUILD-06 Fix: Roxygen @param mismatch**
- **Root cause:** No validation that @param tags match actual function formals
- **Fix:** Added post-generation validation step that:
  - Parses generated code to extract formals
  - Extracts @param names from roxygen
  - Warns if mismatches detected (missing docs or extra docs)
- **Location:** `07_stub_generation.R` lines 1017-1051

**Parse validation:**
- Added `parse(text = result)` check at end of `build_function_stub()`
- Catches syntax errors at generation time rather than at R CMD check
- Aborts with clear error message showing endpoint and parse error

**Testing:**
- Created `tests/testthat/test-stub-generator.R` with 15 assertions covering:
  - Chemi endpoints with string-default options (the "RF" case)
  - CT endpoints with path parameters
  - Roxygen @param/formals alignment
  - Reserved word defaults (TRUE, FALSE, NULL)
- All tests pass

**Commits:**
- `d19b6dc` fix(23-02): stub generator syntax bugs and roxygen mismatch (BUILD-01, BUILD-06)

### Task 2: Schema selection alignment + drift detection (Items 2 & 3)

**Item 2: Schema selection alignment (Approach A from SCHEMA_AUTOMATION_PLAN.md)**

**Problem:**
- Diff reporter processed all schema files
- Stub generator used stage priority to pick one schema per domain
- Result: PR showed changes in dev schema that stub generator ignored

**Solution:**
- Moved `select_schema_files()` from `generate_stubs.R` to `dev/endpoint_eval/01_schema_resolution.R`
- Updated `diff_schemas()` to accept `stage_priority` and `exclude_pattern` parameters
- When stage_priority provided, both diff and stub generator call same selection function
- CI workflow passes `stage_priority = c("prod", "staging", "dev")` and `exclude_pattern = "ui"`

**Changes:**
- `01_schema_resolution.R`: Added `select_schema_files()` function (lines 593-656)
- `diff_schemas.R`: Updated to use `select_schema_files()` when stage_priority provided (lines 208-239)
- `generate_stubs.R`: Removed local definition, sources from 01_schema_resolution.R
- `.github/workflows/schema-check.yml`: Passes stage_priority to diff_schemas call

**Item 3: Parameter drift detection (report-only)**

**Problem:**
- Schema modifications to existing endpoints (new params, removed params) were silent
- No way to know if implemented functions need updates

**Solution:**
- Created `dev/endpoint_eval/08_drift_detection.R` with:
  - `detect_parameter_drift()` - compares schema params vs function formals for existing endpoints
  - `extract_function_params()` - parse-based extraction with regex fallback
  - `FRAMEWORK_PARAMS` constant - params excluded from drift (tidy, verbose, ..., all_pages)
- Returns tibble with columns: endpoint, file, function_name, drift_type, param_name, schema_value, code_value
- Does NOT modify any files (report-only per design)

**Integration:**
- Updated all three stub generators (`generate_ct_stubs`, `generate_chemi_stubs`, `generate_cc_stubs`) to:
  - Call `detect_parameter_drift()` for endpoints with n_hits > 0
  - Return both scaffold results and drift results
  - Write drift report to `drift_report.csv` for CI
- Updated `generate_stubs.R` to output drift_count and drift_endpoints to GITHUB_OUTPUT
- Updated CI workflow to read drift report and add "Parameter Drift Detected" section to PR body

**Testing:**
- Created `tests/testthat/test-drift-detection.R` with 17 assertions covering:
  - `extract_function_params()` correctly extracts formals from real R files
  - FRAMEWORK_PARAMS excluded from drift results
  - param_added detected when schema has new parameter
  - param_removed detected when function has extra parameter
  - Drift report is tibble with expected columns
- All tests pass

**Commits:**
- `8778025` feat(23-02): schema selection alignment + drift detection (Items 2 & 3)

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

**Automated tests:**
```bash
testthat::test_file('tests/testthat/test-stub-generator.R')
# PASS 15/15 assertions

testthat::test_file('tests/testthat/test-drift-detection.R')
# PASS 17/17 assertions
```

**Self-check:**
- ✅ dev/endpoint_eval/07_stub_generation.R modified with syntax fixes
- ✅ dev/endpoint_eval/08_drift_detection.R created with drift detection
- ✅ dev/endpoint_eval/01_schema_resolution.R updated with select_schema_files()
- ✅ dev/generate_stubs.R updated to use shared schema selection and call drift detection
- ✅ dev/diff_schemas.R updated to use shared schema selection
- ✅ .github/workflows/schema-check.yml updated with stage_priority and drift reporting
- ✅ tests/testthat/test-stub-generator.R created with 15 passing tests
- ✅ tests/testthat/test-drift-detection.R created with 17 passing tests
- ✅ Both task commits exist: d19b6dc, 8778025

## Self-Check: PASSED

All files created and modified as expected. All tests pass. Both commits verified.

## Success Criteria Met

- ✅ build_function_stub() generates syntactically valid R for chemi endpoints with default options
- ✅ Generated roxygen @param tags exactly match function formals
- ✅ select_schema_files() lives in 01_schema_resolution.R, shared by diff and stub systems
- ✅ detect_parameter_drift() returns a structured tibble of drifts
- ✅ CI workflow includes drift reporting in PR body
- ✅ All unit tests for stub generator and drift detection pass

## Impact

**BUILD-01 and BUILD-06 fixes:**
- Stub generator now produces valid R syntax for all endpoint types
- Parse validation catches errors at generation time, not at R CMD check
- Roxygen @param documentation automatically matches function formals
- Eliminates entire class of syntax errors in generated stubs

**Schema alignment (Item 2):**
- Diff reporter and stub generator now operate on same canonical schemas per domain
- PR reports are actionable - every change reported has corresponding stub action
- Eliminates confusion from "2 endpoints added" but "0 stubs generated"

**Drift detection (Item 3):**
- Automated detection of schema modifications to existing endpoints
- Clear reporting in PR body: which functions need updates and what changed
- Framework parameters correctly excluded from drift reports
- Report-only design preserves manual edits and custom post-processing

**Overall:**
- Schema automation pipeline is now robust and internally consistent
- Test coverage ensures these fixes remain stable
- CI workflow provides clear, actionable reports for schema updates

## Next Steps

1. Regenerate all experimental stubs with fixed generator (Phase 23 Plan 03)
2. Verify regenerated stubs parse cleanly
3. Continue with build fixes (BUILD-02 through BUILD-08)
4. Rebuild test generator with function metadata reading (TGEN-01 through TGEN-05)
