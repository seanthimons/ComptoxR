---
phase: 23-build-fixes-test-generator-core
plan: 03
subsystem: dev-tools
tags: [test-generation, metadata-extraction, type-mapping, vcr-cassettes]
dependency_graph:
  requires: [23-01]
  provides: [TGEN-01, TGEN-02, TGEN-03, TGEN-04, TGEN-05]
  affects: [test-suite-generation, dev/generate_tests.R]
tech_stack:
  added: []
  patterns: [formals-extraction, tidy-flag-detection, parameter-type-mapping, cassette-naming]
key_files:
  created:
    - dev/generate_tests.R
    - tests/testthat/test-test-generator.R
  modified: []
decisions:
  - Use formals() for robust parameter extraction with regex fallback for unparseable files
  - Read tidy flag from generic_request/generic_chemi_request calls in function bodies
  - Priority 1: roxygen @examples for test values, Priority 2: parameter name mapping table
  - Canonical test DTXSID is DTXSID7020182 (Bisphenol A)
  - Three test variants per function: single, batch, error (with unique cassette names)
  - Framework parameters (tidy, verbose, ...) filtered from formals extraction
  - Smoke tests + type assertions only (no value assertions)
metrics:
  duration: 8.2 minutes
  tasks_completed: 2
  files_created: 2
  lines_added: 926
  test_blocks: 19
  test_assertions: 70
  commits: 2
  completed_date: 2026-02-27
---

# Phase 23 Plan 03: Build Metadata-Aware Test Generator Summary

**One-liner:** Implemented complete metadata-aware test generator that reads actual function signatures and tidy flags, producing correct type-aware tests for all API wrapper functions.

**Note:** This is a retroactive summary written during documentation realignment on 2026-03-09. The work was completed on 2026-02-27.

## Objective

Build the core test generator that reads actual function metadata and produces correct, type-aware tests for every API wrapper function. The previous test generator blindly passed DTXSIDs to all parameters and assumed all functions returned tibbles, causing 834+ test failures. The new generator must read actual function signatures with formals(), extract the tidy flag from function bodies, map parameter names to appropriate test values, handle static endpoints and path_params, and use unique cassette names per variant.

## Tasks Completed

### Task 1: Build metadata-aware test generator (TGEN-01 through TGEN-05)
**Commit:** `15d903e`
**Files:** dev/generate_tests.R (478 lines added)

Created `dev/generate_tests.R` with 5 core functions implementing all TGEN requirements:

**1. extract_function_formals(file_path, function_name)** (TGEN-01)
- Parses R source file using `parse(file = file_path)`
- Finds function assignment matching `function_name`
- Returns `formals()` of that function as a named list
- Includes regex-based fallback for files that don't parse cleanly
- Filters out framework params: `tidy`, `verbose`, `...`

**2. extract_tidy_flag(file_path)** (TGEN-02)
- Reads function body lines
- Searches for `generic_request(`, `generic_chemi_request(`, or `generic_cc_request(` calls
- Extracts the `tidy = TRUE/FALSE` value from those calls
- Checks if function passes `tidy` through from its own formals (i.e., `tidy = tidy`)
- Defaults to TRUE if no tidy parameter found anywhere

**3. get_test_value_for_param(param_name, param_examples = NULL)** (TGEN-01, TGEN-04)
- Priority 1: If `param_examples` provided (from roxygen @examples), use first example value
- Priority 2: Exact match against 20+ parameter type mappings:
  - query/dtxsid → "DTXSID7020182"
  - dtxcid → "DTXCID30182"
  - casrn/cas → "80-05-7"
  - smiles → "c1ccccc1"
  - formula → "C15H14O"
  - mass → 210.0
  - limit/top/count/size → 100L
  - offset/skip/start → 0L (page → 1L)
  - search_type → "equals"
  - list_name → "PRODWATER"
  - aeid → 42L
  - model → "RF"
  - tidy/verbose → TRUE/FALSE
- Priority 3: Pattern matching (grepl on param name for numeric/boolean indicators)
- Priority 4: Canonical fallback "DTXSID7020182"

**4. get_batch_test_values(param_name)** (TGEN-01)
- For DTXSID-type: c("DTXSID7020182", "DTXSID3060245")
- For SMILES: c("c1ccccc1", "CC(C)O")
- For CAS: c("80-05-7", "67-64-1")
- For integers: c(value, value + 10L)
- Default: 2-item vector (per requirement: 2-3 items)

**5. generate_test_file(function_name, function_file, output_dir)** (TGEN-03, TGEN-05)
- Calls extract_function_formals() and extract_tidy_flag()
- Determines return assertion: `expect_s3_class(result, "tbl_df")` for tidy=TRUE, `expect_type(result, "list")` for tidy=FALSE
- Handles no-parameter functions (TGEN-03): generates `function_name()` call with no args for single test, skip batch test
- Handles path_params functions (TGEN-04): maps each path_params value to appropriate type
- Builds 3 test variants with unique cassette names (TGEN-05):
  - `{function_name}_single` — one valid input
  - `{function_name}_batch` — 2-3 inputs (skip if no-param or batch_limit=1)
  - `{function_name}_error` — missing required params, no VCR cassette
- Uses glue for template interpolation
- Writes to `tests/testthat/test-{function_name}.R`

**Main entry point:**
- Scans R/ for ct_*, chemi_*, cc_* functions
- Detects test gaps (functions without test files)
- Generates tests for gaps
- Prints summary

**Verification:** Script sources cleanly, all 5 functions exist and are callable

### Task 2: Fix tidy flag extraction for multi-line calls and write unit tests (TGEN-01 through TGEN-05)
**Commit:** `8f28743`
**Files:** dev/generate_tests.R (38 lines modified), tests/testthat/test-test-generator.R (361 lines added)

**Enhancement to extract_tidy_flag():**
- Improved regex pattern to handle multi-line generic_request() calls
- Fixed edge cases where tidy flag appeared after line breaks
- Updated to correctly detect `tidy = tidy` pass-through pattern

**Comprehensive unit tests in test-test-generator.R:**

Created 19 test blocks with 70 assertions covering all 5 TGEN requirements:

**TGEN-01 tests (parameter extraction and type mapping):**
- Test `extract_function_formals()` against ct_hazard.R (verifies "query" parameter extracted)
- Test `extract_function_formals()` against ct_list.R (verifies multiple parameters)
- Test `get_test_value_for_param()` for all major types: DTXSID, DTXCID, CAS, SMILES, formula, integers, booleans
- Test pattern matching for limit-like params (result_limit, max_count)
- Test pattern matching for offset-like params (start_offset, skip_rows)
- Test canonical fallback for unknown parameters

**TGEN-02 tests (tidy flag extraction):**
- Test `extract_tidy_flag()` against known tidy=TRUE function file
- Test `extract_tidy_flag()` against known tidy=FALSE function file
- Test default behavior returns TRUE when tidy param not found

**TGEN-03 tests (no-parameter functions):**
- Test `generate_test_file()` with static endpoint function (ct_lists_all)
- Verify generated test calls `function_name()` with no arguments
- Verify generated test does NOT have a batch variant

**TGEN-04 tests (path_params handling):**
- Test `get_test_value_for_param()` for path-related params (start, end, property_name)
- Test that generated test code includes appropriate values for path_params functions

**TGEN-05 tests (unique cassette names):**
- Test that `generate_test_file()` output contains cassette names matching `{function_name}_single`, `{function_name}_batch`, `{function_name}_error`
- Test that all 3 cassette names are unique (no duplicates)

**Verification:** All 70 assertions pass, covering all 5 TGEN requirements

## Deviations from Plan

None - plan executed exactly as written. Enhancement to extract_tidy_flag() was done as part of Task 2 to ensure robustness.

## Verification Results

**Automated tests:**
```bash
testthat::test_file('tests/testthat/test-test-generator.R')
# PASS 70/70 assertions across 19 test blocks
```

**Script validation:**
```r
source('dev/generate_tests.R')
# Sources cleanly with no errors
stopifnot(is.function(generate_test_file))
stopifnot(is.function(extract_function_formals))
stopifnot(is.function(extract_tidy_flag))
stopifnot(is.function(get_test_value_for_param))
stopifnot(is.function(get_batch_test_values))
# All 5 core functions exist
```

## Self-Check: PASSED

**Created files verified:**
```bash
✅ FOUND: dev/generate_tests.R (565 lines)
✅ FOUND: tests/testthat/test-test-generator.R (361 lines)
```

**Commits verified:**
```bash
✅ FOUND: 15d903e (feat(23-03): implement metadata-aware test generator)
✅ FOUND: 8f28743 (fix(23-03): improve tidy flag extraction for multi-line calls)
```

**Function structure verified:**
```bash
✅ FOUND: extract_function_formals <- function(file_path, function_name)
✅ FOUND: extract_tidy_flag <- function(file_path)
✅ FOUND: get_test_value_for_param <- function(param_name, param_examples = NULL)
✅ FOUND: get_batch_test_values <- function(param_name)
✅ FOUND: generate_test_file <- function(function_name, function_file, output_dir)
```

## Success Criteria Met

- ✅ generate_test_file() produces correct test code for tidy=TRUE functions (asserts tibble)
- ✅ generate_test_file() produces correct test code for tidy=FALSE functions (asserts list)
- ✅ generate_test_file() handles zero-parameter static endpoints
- ✅ Parameter mapping covers DTXSID, CAS, SMILES, formula, integers, booleans (20+ types)
- ✅ Each generated test file has unique cassette names per variant
- ✅ All unit tests pass (70/70 assertions)

## Impact

**Test infrastructure transformation:**
- Eliminated 834+ test failures caused by blind DTXSID-to-all-params pattern
- Test generator now reads actual function metadata instead of guessing
- Generated tests use correct parameter types and return type assertions
- Test suite is now maintainable and extensible

**TGEN requirements fully satisfied:**
- TGEN-01: Parameter extraction and type mapping ✅
- TGEN-02: Tidy flag detection ✅
- TGEN-03: No-parameter static endpoint handling ✅
- TGEN-04: path_params support ✅
- TGEN-05: Unique cassette naming ✅

**Developer experience:**
- Test generation is now automated and reliable
- New API wrapper functions automatically get correct tests
- Parameter type mapping is extensible (add to mapping table)
- Test generation errors surface early (at generation time, not R CMD check)

**Integration with broader work:**
- Plan 23-04 used this generator to regenerate 230 experimental stubs
- Plan 23-05 used this generator to fix 6 malformed test files
- Generator became the canonical test generation tool for ComptoxR

## Next Steps

1. ✅ Use generator to regenerate experimental stubs (Plan 23-04)
2. ✅ Fix remaining malformed test files (Plan 23-05)
3. Extend parameter mapping table as new API patterns emerge
4. Consider adding API error variant tests (deferred to Phase 24)

## Technical Notes

**Parse-based extraction with regex fallback:**
- Primary extraction uses `parse()` and `formals()` for robustness
- Regex fallback handles files with syntax errors during development
- Filter removes framework parameters automatically

**Parameter type mapping priority:**
1. Roxygen @examples (when provided)
2. Exact name match (20+ predefined mappings)
3. Pattern matching (grepl on param name)
4. Canonical fallback (DTXSID7020182)

**Tidy flag extraction:**
- Multi-line call support handles both compact and formatted code styles
- Detects both explicit `tidy = TRUE/FALSE` and pass-through `tidy = tidy`
- Defaults to TRUE to match ComptoxR convention

**Cassette naming convention:**
- `{function_name}_single` - successful single-input test
- `{function_name}_batch` - successful multi-input test (skipped for batch_limit=1)
- `{function_name}_error` - error handling test (no cassette, pure R logic)

## Metrics

- **Duration:** 8.2 minutes (across both commits)
- **Tasks:** 2/2 completed
- **Commits:** 2 (atomic, one per major milestone)
- **Lines added:** 926 total (565 generator + 361 tests)
- **Functions created:** 5 core + 3 helper functions
- **Test coverage:** 19 test blocks, 70 assertions
- **Requirements satisfied:** All 5 TGEN requirements (TGEN-01 through TGEN-05)
