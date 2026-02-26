# Architecture Patterns: Test Infrastructure Integration

**Domain:** R package test infrastructure
**Researched:** 2026-02-26

## Executive Summary

ComptoxR's test infrastructure must integrate three automated workflows: stub generation → test generation → VCR cassette recording. The current architecture has separate pipelines for stub creation (`dev/generate_stubs.R`) and test generation (`tests/testthat/tools/helper-test-generator-v2.R`), with no automated coordination between them. VCR cassettes are manually managed via helper functions. CI workflows check coverage but don't detect stub-test gaps.

The integration challenge is synchronizing these three pipelines while respecting existing architecture constraints: stub generation runs in CI via GitHub Actions, test files live in `tests/testthat/`, cassettes record on first run requiring API keys, and R CMD check excludes `dev/` from built packages.

**Recommended architecture:** Event-driven pipeline with detection-then-generation pattern. After stubs are generated, detect which functions lack tests, generate test files for those functions, commit both stubs and tests together, then cassettes record on CI's first test run with API key. Test generator reads function metadata directly from generated stubs to produce correct parameter types and return type assertions.

## Component Boundaries

### Existing Components (No Changes Required)

| Component | Responsibility | Location | Stability |
|-----------|---------------|----------|-----------|
| **Stub Generation Pipeline** | Parse OpenAPI schemas, generate R function stubs with roxygen docs | `dev/endpoint_eval/` (8 files) + `dev/generate_stubs.R` | **Stable** - v1.9 shipped, comprehensive test coverage (95+ tests), lifecycle guards in place |
| **Generic Request Templates** | Execute HTTP requests with batching, auth, retry logic | `R/z_generic_request.R` | **Stable** - Core infrastructure used by all wrappers |
| **VCR Configuration** | Configure vcr for cassette recording/playback | `tests/testthat/helper-vcr.R` | **Stable** - 13 lines, basic config |
| **CI Workflows** | Run tests, check coverage, trigger stub generation | `.github/workflows/` | **Stable** - 4 workflows (test-coverage.yml, pipeline-tests.yml, R-CMD-check.yml, test-quick.yml) |

### Existing Components (Require Modifications)

| Component | Current State | Required Changes | Integration Point |
|-----------|---------------|------------------|-------------------|
| **Test Generator v2** | Exists at `tests/testthat/tools/helper-test-generator-v2.R` (421 lines). Extracts metadata from function files, generates 4 test types (basic, example, batch, error). Uses `determine_test_input_type()` to map parameters to appropriate test data. | Must read `tidy` parameter from stub to assert correct return type (tibble vs list). Must parse function signature more robustly to avoid DTXSID→non-DTXSID parameter errors. Needs batch detection from `generic_request` metadata. | Reads: `R/*.R` files (stubs)<br>Writes: `tests/testthat/test-*.R` files |
| **Function Metadata Extractor** | Exists at `tests/testthat/tools/helper-function-metadata.R` (150+ lines). Parses roxygen comments, function signatures, examples. Extracts `generic_request()` call details. | Must reliably extract `tidy` parameter value from `generic_request()` call. Must handle `path_params`, `batch_limit`, `method` metadata for correct test generation. | Used by: Test Generator v2 |
| **VCR Cassette Helpers** | Exists at `tests/testthat/helper-vcr.R` (13 lines config) + `helper-api.R` has cassette management functions. | No code changes needed. May need orchestration script for mass deletion/re-recording. | Interacts with: VCR package during test runs |

### New Components (Need to Build)

| Component | Purpose | Location | Inputs | Outputs |
|-----------|---------|----------|--------|---------|
| **Test Gap Detector** | Scan `R/` for functions without corresponding test files. Identify stubs that need tests generated. | `dev/detect_test_gaps.R` (new script, ~100 lines) | **In:** `R/ct_*.R`, `R/chemi_*.R`, `R/cc_*.R` stubs<br>**In:** `tests/testthat/test-*.R` existing tests<br>**In:** Stub generation result from `dev/generate_stubs.R` (GITHUB_OUTPUT: `stubs_generated=N`) | **Out:** List of function names needing tests<br>**Out:** GITHUB_OUTPUT: `missing_tests=N`<br>**Out:** `dev/logs/test-gaps-YYYY-MM-DD.txt` (log file) |
| **Batch Test Generator** | Generate test files for multiple functions at once. Wrapper around test-generator-v2. | `dev/generate_tests.R` (new orchestrator, ~150 lines) | **In:** List of function names from Test Gap Detector<br>**In:** Metadata from Function Metadata Extractor | **Out:** `tests/testthat/test-*.R` files<br>**Out:** Summary report (created N tests, skipped M) |
| **Cassette Cleanup Script** | Delete cassettes for functions with incorrect parameters (identified by test failures). Option to delete all cassettes for re-recording. | `dev/cleanup_cassettes.R` (new utility, ~80 lines) | **In:** Test failure logs (optional)<br>**In:** Function name patterns to target | **Out:** Deleted cassette files<br>**Out:** Summary log |
| **CI Test Generation Workflow** | Detect stub-test gaps after stub generation, trigger test generation, commit results. | `.github/workflows/generate-tests.yml` (new workflow, ~120 lines YAML) | **Trigger:** After `generate_stubs.R` runs OR manual workflow_dispatch<br>**In:** Stub generation output (stubs_generated count) | **Out:** Commit with new test files<br>**Out:** PR comment with summary |

## Data Flow

### Current Flow (Before Integration)

```
┌─────────────────┐
│ OpenAPI Schemas │
└────────┬────────┘
         │
         v
┌─────────────────────────┐
│ dev/generate_stubs.R    │  (Runs in CI or manually)
│ • Parse schemas         │
│ • Generate R stubs      │
│ • Write to R/           │
└────────┬────────────────┘
         │
         │ (Manual step - user notices new stubs)
         │
         v
┌─────────────────────────────────────┐
│ tests/testthat/tools/               │
│   helper-test-generator-v2.R        │  (Run manually)
│ • Extract function metadata         │
│ • Generate test code                │
└────────┬────────────────────────────┘
         │
         │ (Manual file creation)
         │
         v
┌─────────────────────────────────────┐
│ tests/testthat/test-*.R             │
└────────┬────────────────────────────┘
         │
         │ (First test run with API key)
         │
         v
┌─────────────────────────────────────┐
│ tests/testthat/fixtures/*.yml       │  (VCR cassettes)
└─────────────────────────────────────┘

⚠️ GAPS:
- No automatic test generation after stub creation
- Manual orchestration required
- 673 untracked cassettes with bad parameters (TODO.md line 33)
- CI doesn't report stub-test gaps
```

### Proposed Integrated Flow

```
┌─────────────────┐
│ OpenAPI Schemas │
└────────┬────────┘
         │
         v
┌──────────────────────────────────────────────────────────┐
│ CI: Schema Check Workflow                                │
│ • Download schemas                                       │
│ • Detect changes                                         │
│ • Trigger stub generation if changes detected            │
└────────┬─────────────────────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────────────────────┐
│ dev/generate_stubs.R                                     │
│ • Parse schemas → endpoint specs                         │
│ • Generate function stubs                                │
│ • Write to R/ (with lifecycle protection)                │
│ • Output: GITHUB_OUTPUT: stubs_generated=N              │
└────────┬─────────────────────────────────────────────────┘
         │
         │ (Automated trigger)
         │
         v
┌──────────────────────────────────────────────────────────┐
│ dev/detect_test_gaps.R (NEW)                             │
│ • Scan R/ for all ct_*/chemi_*/cc_* functions            │
│ • Check tests/testthat/ for corresponding test-*.R       │
│ • Output: List of functions without tests                │
│ • Output: GITHUB_OUTPUT: missing_tests=N                 │
└────────┬─────────────────────────────────────────────────┘
         │
         │ (If missing_tests > 0)
         │
         v
┌──────────────────────────────────────────────────────────┐
│ dev/generate_tests.R (NEW)                               │
│ For each function without tests:                         │
│   1. Call extract_function_metadata(R/fn.R)              │
│   2. Call create_metadata_based_test_file()              │
│   3. Write tests/testthat/test-fn.R                      │
│ Output: Summary report (N tests created)                 │
└────────┬─────────────────────────────────────────────────┘
         │
         │ (Automated commit in CI)
         │
         v
┌──────────────────────────────────────────────────────────┐
│ Git Commit                                               │
│ • Commit new test files                                  │
│ • PR comment: "Generated tests for N new functions"      │
└────────┬─────────────────────────────────────────────────┘
         │
         │ (CI runs tests on PR)
         │
         v
┌──────────────────────────────────────────────────────────┐
│ CI: Test Workflow                                        │
│ • First run: vcr records cassettes (requires API key)    │
│ • Tests may fail if parameters wrong (expected)          │
│ • Artifacts uploaded: failure logs                       │
└────────┬─────────────────────────────────────────────────┘
         │
         │ (If test failures due to bad parameters)
         │
         v
┌──────────────────────────────────────────────────────────┐
│ Manual Fix Loop                                          │
│ 1. dev/cleanup_cassettes.R (delete bad cassettes)        │
│ 2. Fix test generator parameter logic                    │
│ 3. Re-run dev/generate_tests.R (overwrite bad tests)     │
│ 4. Re-run tests (re-record cassettes)                    │
└──────────────────────────────────────────────────────────┘

✅ IMPROVEMENTS:
- Automated test generation after stub creation
- CI reports test coverage gaps
- Cassette re-recording via cleanup script
- Test generator fixes reduce bad parameter errors
```

## Integration Points

### 1. Stub Generation → Test Gap Detection

**Trigger:** `dev/generate_stubs.R` completes and writes GITHUB_OUTPUT.

**Data passed:**
- `stubs_generated=N` (integer count from GITHUB_OUTPUT)
- Modified files list (from git diff)

**Implementation:**
```yaml
# .github/workflows/generate-tests.yml
steps:
  - name: Generate stubs
    id: stubs
    run: Rscript dev/generate_stubs.R

  - name: Detect test gaps
    id: gaps
    if: steps.stubs.outputs.stubs_generated > 0
    run: Rscript dev/detect_test_gaps.R
```

**Contract:**
- Stub generator MUST write `stubs_generated` to GITHUB_OUTPUT
- Test gap detector reads git diff to find new R files
- Test gap detector outputs `missing_tests` count to GITHUB_OUTPUT

### 2. Test Gap Detection → Test Generation

**Trigger:** Test gap detector finds `missing_tests > 0`.

**Data passed:**
- List of function names (written to temp file: `dev/logs/functions-needing-tests.txt`)
- Each line: function name (e.g., `ct_hazard`)

**Implementation:**
```r
# dev/generate_tests.R reads list
functions <- readLines("dev/logs/functions-needing-tests.txt")
for (fn_name in functions) {
  metadata <- extract_function_metadata(file.path("R", paste0(fn_name, ".R")))
  create_metadata_based_test_file(
    metadata = metadata,
    output_file = file.path("tests/testthat", paste0("test-", fn_name, ".R"))
  )
}
```

**Contract:**
- Test gap detector writes function list to `dev/logs/functions-needing-tests.txt`
- Test generator reads list, generates tests for each
- Test generator reports success/failure counts

### 3. Test Generation → VCR Cassette Recording

**Trigger:** New test files committed, CI runs test suite.

**Data passed:**
- Test files with `vcr::use_cassette()` calls
- Cassette names follow pattern: `{function_name}_{variant}` (e.g., `ct_hazard_single`, `ct_hazard_batch`)

**Implementation:**
```r
# In generated test file
test_that("ct_hazard works with single input", {
  vcr::use_cassette("ct_hazard_single", {
    result <- ct_hazard("DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})
```

**First run behavior:**
- VCR detects missing cassette
- Makes live API request (requires API key in CI secrets)
- Records response to `tests/testthat/fixtures/ct_hazard_single.yml`
- Test passes/fails based on actual response

**Subsequent runs:**
- VCR loads cassette from fixtures/
- No API request made
- Test runs against recorded response

**Contract:**
- Test generator produces unique cassette names per test
- CI environment has `ctx_api_key` secret configured
- First run may fail (expected if API returns errors)
- Failed cassettes can be deleted and re-recorded

### 4. Test Failures → Cassette Cleanup

**Trigger:** Test failures due to incorrect parameters (manual analysis).

**Data passed:**
- Test failure logs (from CI artifacts)
- Cassette names extracted from logs

**Implementation:**
```r
# dev/cleanup_cassettes.R
delete_cassettes_for_function <- function(function_name) {
  pattern <- paste0("^", function_name, "_.*\\.yml$")
  cassettes <- list.files("tests/testthat/fixtures", pattern = pattern, full.names = TRUE)
  file.remove(cassettes)
  cli::cli_alert_info("Deleted {length(cassettes)} cassette(s) for {function_name}")
}

# Usage
delete_cassettes_for_function("ct_chemical_list_search_by_type")  # Wrong param error
```

**Contract:**
- Cassette cleanup script takes function name or pattern
- Deletes matching cassettes from fixtures/
- Next test run re-records from live API
- Cleanup script logs actions to `dev/logs/cassette-cleanup-YYYY-MM-DD.txt`

### 5. CI Workflow → Gap Reporting

**Trigger:** Any commit to main/PR branches.

**Data passed:**
- Count of functions without tests (from detect_test_gaps.R)
- Coverage percentage (from covr)

**Implementation:**
```yaml
# .github/workflows/generate-tests.yml
- name: Report test gaps
  if: always()
  run: |
    echo "## Test Coverage Report" >> $GITHUB_STEP_SUMMARY
    echo "" >> $GITHUB_STEP_SUMMARY
    echo "**Functions without tests:** ${{ steps.gaps.outputs.missing_tests }}" >> $GITHUB_STEP_SUMMARY
    echo "**R/ coverage:** ${{ steps.coverage.outputs.r_pct }}%" >> $GITHUB_STEP_SUMMARY
```

**Contract:**
- CI workflow writes summary to GitHub Actions summary
- PR comments show test gap count
- Coverage enforcement remains at 75% (rOpenSci requirement)

## Architecture Patterns

### Pattern 1: Detection-Then-Generation

**What:** Separate detection phase from generation phase. Don't generate tests blindly; first check what's missing.

**Why:** Avoids overwriting existing tests, respects manually written tests, enables incremental generation.

**When:** After stub generation completes, before test generation starts.

**Example:**
```r
# dev/detect_test_gaps.R
detect_test_gaps <- function() {
  # 1. Find all exported functions in R/
  r_files <- list.files("R", pattern = "^(ct|chemi|cc)_.*\\.R$", full.names = TRUE)
  functions <- purrr::map_chr(r_files, ~ {
    tools::file_path_sans_ext(basename(.x))
  })

  # 2. Check which have corresponding test files
  test_files <- list.files("tests/testthat", pattern = "^test-.*\\.R$")
  tested_functions <- stringr::str_remove(test_files, "^test-") %>%
    stringr::str_remove("\\.R$")

  # 3. Return gap
  missing <- setdiff(functions, tested_functions)

  list(
    total_functions = length(functions),
    tested_functions = length(tested_functions),
    missing_tests = missing
  )
}
```

### Pattern 2: Metadata-Driven Test Generation

**What:** Generate tests based on actual function metadata (parameters, return types) extracted from source files, not assumptions.

**Why:** Prevents type mismatches (DTXSID passed to `limit` parameter), return type assertion errors (tibble vs list), wrong test patterns for GET vs POST.

**When:** Test generator reads function metadata before generating test code.

**Example:**
```r
# tests/testthat/tools/helper-test-generator-v2.R
generate_basic_test <- function(metadata, test_inputs) {
  # Read actual tidy parameter from function
  tidy_value <- metadata$generic_request$tidy  # Extract from function body

  # Generate correct expectations
  if (tidy_value == TRUE || is.null(tidy_value)) {  # Default is TRUE
    expectations <- quote({
      expect_s3_class(result, "tbl_df")
    })
  } else {
    expectations <- quote({
      expect_type(result, "list")
    })
  }

  # Rest of test generation...
}
```

**Current bug:** Test generator doesn't read `tidy` parameter, always assumes tibble return. Causes 122 test failures (TODO.md line 23).

### Pattern 3: Cassette-Per-Test-Variant

**What:** Each test variant (single, batch, error, example) gets its own uniquely named cassette.

**Why:** Isolates request/response pairs, enables selective re-recording, prevents cassette conflicts.

**When:** Test generator creates tests with `vcr::use_cassette()`.

**Example:**
```r
# Generated test structure
test_that("ct_hazard works with single input", {
  vcr::use_cassette("ct_hazard_single", {  # Unique cassette
    result <- ct_hazard("DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})

test_that("ct_hazard handles batch requests", {
  vcr::use_cassette("ct_hazard_batch", {  # Different cassette
    result <- ct_hazard(c("DTXSID7020182", "DTXSID5032381"))
    expect_s3_class(result, "tbl_df")
  })
})
```

**Cassette naming convention:**
- `{function_name}_single` - Single input test
- `{function_name}_batch` - Batch input test
- `{function_name}_error` - Error handling test
- `{function_name}_example` - Example-based test
- `{function_name}_basic` - No-parameter functions

**Benefits:**
- Easy to identify which test a cassette belongs to
- Can delete cassettes by pattern (e.g., all `*_batch` cassettes)
- Enables incremental re-recording (just batch tests, just error tests)

### Pattern 4: Lifecycle Protection Guard

**What:** Prevent automated tools from overwriting stable/maturing functions.

**Why:** Functions marked `@lifecycle stable` are production code that should not be touched by stub generators or test generators.

**When:** Before writing any file, check for lifecycle badges.

**Existing implementation:**
```r
# dev/endpoint_eval/05_file_scaffold.R
has_protected_lifecycle <- function(path) {
  protected_statuses <- c("stable", "maturing", "superseded", "deprecated", "defunct")
  lines <- readLines(path, warn = FALSE)

  badges <- str_extract_all(lines, 'lifecycle::badge\\("([^"]+)"\\)')
  statuses <- str_extract(unlist(badges), '(?<=badge\\(")[^"]+')

  any(tolower(statuses) %in% protected_statuses)
}

scaffold_files <- function(..., overwrite = FALSE, append = FALSE) {
  # ...
  if (existed && (overwrite || append)) {
    if (has_protected_lifecycle(path)) {
      return(tibble(action = "skipped_lifecycle", ...))
    }
  }
  # ...
}
```

**Application to test generator:**
Test generator should also check lifecycle before overwriting test files. If a test file has `# Protected by lifecycle badge` comment at top, skip generation.

```r
# dev/generate_tests.R
has_protected_test <- function(test_file) {
  if (!file.exists(test_file)) return(FALSE)
  lines <- readLines(test_file, n = 5, warn = FALSE)
  any(grepl("# Protected|# Do not auto-generate", lines))
}
```

### Pattern 5: Two-Phase Cassette Recording

**What:** Separate cassette recording into two phases: initial recording (may fail), then fix and re-record.

**Why:** First API requests may return errors, bad parameters, or unexpected formats. Don't commit bad cassettes. Fix tests, delete cassettes, re-record clean.

**When:** First CI run after test generation records cassettes. Manual intervention fixes bad tests, then re-runs.

**Flow:**
```
Phase 1: Initial Recording (CI)
├─ Test generated with wrong parameters
├─ VCR records error response
├─ Test fails (expected)
└─ Cassette committed (intentionally, for debugging)

Phase 2: Fix and Re-record (Manual)
├─ Developer reviews failure logs
├─ Identifies parameter error in test generator
├─ Runs: dev/cleanup_cassettes.R "function_name"
├─ Fixes test generator logic
├─ Re-runs: dev/generate_tests.R (overwrites bad test)
├─ CI re-runs tests (re-records clean cassette)
└─ Test passes, clean cassette committed
```

**Cassette quality check:**
```r
# tests/testthat/helper-api.R (existing)
check_cassette_safety <- function(cassette_name) {
  file <- file.path("tests/testthat/fixtures", paste0(cassette_name, ".yml"))
  content <- readLines(file, warn = FALSE)

  # Check for sensitive data
  if (any(grepl("api[_-]?key", content, ignore.case = TRUE))) {
    warning("Cassette contains potential API key: ", cassette_name)
  }

  # Check for error responses
  if (any(grepl("error|invalid|failed", content, ignore.case = TRUE))) {
    message("Cassette may contain error response: ", cassette_name)
  }
}
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Assume All Parameters Are DTXSIDs

**What:** Test generator blindly uses DTXSIDs for every function's first parameter.

**Why bad:** Many functions take non-DTXSID parameters (list names, formulas, property names, pagination limits). Causes test failures and bad cassettes.

**Current evidence:** TODO.md line 24 lists 7 functions with wrong parameter types:
- `chemi_amos_method_pagination` - `limit = "DTXSID7020182"` (should be numeric)
- `ct_chemical_list_search_by_type` - `search_type = "DTXSID7020182"` (should be "Public")

**Instead:**
```r
# tests/testthat/tools/helper-test-generator-v2.R
determine_test_input_type <- function(param_name, metadata) {
  # Map parameter name to appropriate test data type
  param_map <- list(
    query = "query_dtxsid",
    list_name = "list_name",
    dtxsid = "dtxsid",
    limit = "pagination_limit",  # NEW
    offset = "pagination_offset", # NEW
    search_type = "list_type"     # NEW
  )

  param_map[[param_name]] %||% "query_dtxsid"
}

# Add pagination test inputs
get_standard_test_inputs <- function() {
  list(
    # ... existing ...
    pagination_limit = list(single = 10, batch = 50),
    pagination_offset = list(single = 0, batch = 20),
    list_type = list(single = "Public", batch = c("Public", "Private"))
  )
}
```

### Anti-Pattern 2: Commit All Cassettes Immediately

**What:** Git tracks all cassettes including ones with bad parameters or error responses.

**Why bad:** Bad cassettes pollute the repository, make it hard to identify clean test data, cause tests to pass when they shouldn't (testing against error responses).

**Current evidence:** TODO.md line 33: "673 untracked VCR cassettes — many were recorded with wrong parameter values".

**Instead:**
```bash
# .gitignore approach (selective ignoring)
tests/testthat/fixtures/*_error.yml  # Ignore error cassettes until verified

# OR: Manual review before commit
dev/cleanup_cassettes.R --review  # Shows cassettes with error responses
# Developer reviews, deletes bad ones, commits clean ones
```

**Workflow:**
1. First test run generates cassettes (all untracked)
2. CI uploads cassettes as artifacts (not committed)
3. Developer reviews artifacts, identifies bad cassettes
4. Runs cleanup script to delete bad cassettes
5. Re-records clean cassettes
6. Commits only clean cassettes

### Anti-Pattern 3: Overwrite Manually Written Tests

**What:** Test generator overwrites tests that developers have manually refined (better assertions, edge cases, comments).

**Why bad:** Loss of manual test improvements, discourages manual test writing.

**Prevention:**
```r
# dev/generate_tests.R
generate_test_file <- function(metadata, output_file) {
  if (file.exists(output_file)) {
    # Check if manually protected
    if (has_protected_test(output_file)) {
      cli::cli_alert_warning("Skipping protected test: {basename(output_file)}")
      return(NULL)
    }

    # Check if modified recently (assume manual edits)
    mtime <- file.mtime(output_file)
    if (difftime(Sys.time(), mtime, units = "days") < 7) {
      cli::cli_alert_warning("Skipping recently modified test: {basename(output_file)}")
      return(NULL)
    }
  }

  # Generate test...
}
```

**Protection mechanism:**
- Add comment at top of auto-generated tests: `# AUTO-GENERATED - DO NOT EDIT MANUALLY`
- If developer removes comment, test generator skips file (assumes manual refinement)
- Lifecycle badge in test file: `# Protected by lifecycle badge` (future enhancement)

### Anti-Pattern 4: Generate Tests Before Stubs Are Stable

**What:** Run test generator immediately after stub generator, before stubs are reviewed or fixed.

**Why bad:** Generated stubs may have syntax errors (e.g., `"RF" <- model = "RF"` in TODO.md line 8), duplicate parameters, missing required params. Tests against bad stubs will fail or crash.

**Current evidence:** TODO.md lines 7-9 list build errors from stub generator producing invalid R code.

**Instead:**
```yaml
# .github/workflows/generate-tests.yml
- name: Validate generated stubs
  id: validate
  run: |
    # Syntax check all generated stubs
    Rscript -e '
      stubs <- list.files("R", pattern = "^(ct|chemi|cc)_.*\\.R$", full.names = TRUE)
      errors <- purrr::map_lgl(stubs, ~ {
        tryCatch({
          parse(.x)
          FALSE
        }, error = function(e) TRUE)
      })
      if (any(errors)) {
        cat("Syntax errors in generated stubs:\n")
        print(stubs[errors])
        quit(status = 1)
      }
    '

- name: Generate tests
  if: steps.validate.outcome == 'success'
  run: Rscript dev/generate_tests.R
```

**Validation steps:**
1. Parse all generated R files (check syntax)
2. Check for duplicate parameters in function signatures
3. Check for invalid assignment operators
4. Check for missing required dependencies

### Anti-Pattern 5: No Test-to-Function Traceability

**What:** Tests don't clearly indicate which function they test, making it hard to track coverage gaps.

**Why bad:** Can't easily answer "does function X have tests?" without scanning test file contents.

**Instead:**
```r
# Strict naming convention
# R/ct_hazard.R → tests/testthat/test-ct_hazard.R

# Test file header (auto-generated)
# Tests for ct_hazard
# Generated: 2026-02-26
# Source: R/ct_hazard.R
# Return type: tibble
# Parameters: query (DTXSIDs)
```

**Detection script uses this:**
```r
# dev/detect_test_gaps.R
detect_test_gaps <- function() {
  r_files <- list.files("R", pattern = "^(ct|chemi|cc)_.*\\.R$")
  function_names <- tools::file_path_sans_ext(r_files)

  test_files <- list.files("tests/testthat", pattern = "^test-.*\\.R$")
  tested_names <- stringr::str_remove(test_files, "^test-") %>%
    stringr::str_remove("\\.R$")

  missing <- setdiff(function_names, tested_names)

  tibble::tibble(
    function_name = missing,
    source_file = file.path("R", paste0(missing, ".R")),
    expected_test = file.path("tests/testthat", paste0("test-", missing, ".R"))
  )
}
```

## Scalability Considerations

### At Current Scale (371 functions)

| Concern | Approach |
|---------|----------|
| Test generation time | Sequential generation acceptable (~1-2 min for all functions). Metadata extraction is fast (parse R code). |
| Cassette storage | 673 cassettes × ~5KB avg = ~3.4MB. Git handles this fine. VCR uses YAML (text), compresses well. |
| CI test runtime | 324 test files take ~10-15 min with cassettes (no API calls). First run slower (recording). |
| Test maintenance | Test generator handles 90% of cases. Manual refinement for edge cases (10%). |

### At 1000+ Functions

| Concern | Approach |
|---------|----------|
| Test generation time | Parallelize: Use `future` package to generate tests in parallel. Estimated 5-10 functions/sec → ~3-5 min for 1000. |
| Cassette storage | 1000 functions × 4 test variants × 5KB = ~20MB cassettes. Consider compression or external storage. |
| CI test runtime | Split into parallel jobs: Run 100 functions per job × 10 jobs = ~15 min total. |
| Test maintenance | Category-based generation: Generate tests by API domain (ct_*, chemi_*, cc_*) separately. Easier to review. |

### At 5000+ Functions (Enterprise Scale)

| Concern | Approach |
|---------|----------|
| Test generation time | Incremental generation: Only generate tests for changed functions. Cache metadata extraction. |
| Cassette storage | External storage: Move cassettes to S3/artifact storage, download on-demand during tests. Git LFS for large cassettes. |
| CI test runtime | Distributed testing: Use GitHub Actions matrix strategy, run 500 functions per job × 10 parallel jobs. |
| Test maintenance | Automated test repair: Detect failing tests, auto-regenerate, auto-fix parameter types. ML-based test generation (future). |

## Build Order and Dependencies

### Phase 1: Fix Existing Blockers (Before Integration)

**Prerequisites:** None (fixes existing code)

**Tasks:**
1. Fix stub generator syntax errors (TODO.md line 8-9)
2. Fix duplicate parameter bugs in generated stubs
3. Fix test generator to respect `tidy` parameter
4. Fix test generator parameter type detection

**Outcome:** Clean baseline for integration work

**Estimated effort:** 2-3 days

### Phase 2: Build New Components (Core Integration)

**Prerequisites:** Phase 1 complete

**Tasks:**
1. Create `dev/detect_test_gaps.R` (detection script)
2. Create `dev/generate_tests.R` (batch orchestrator)
3. Update `helper-test-generator-v2.R` to fix parameter type detection
4. Update `helper-function-metadata.R` to extract `tidy` parameter

**Dependencies:**
- `detect_test_gaps.R` → uses existing R/ files
- `generate_tests.R` → uses `helper-test-generator-v2.R`
- Test generator updates → use `helper-function-metadata.R`

**Outcome:** Can generate tests for gap list manually

**Estimated effort:** 3-4 days

### Phase 3: CI Workflow Integration (Automation)

**Prerequisites:** Phase 2 complete, test generator working correctly

**Tasks:**
1. Create `.github/workflows/generate-tests.yml`
2. Update `generate_stubs.R` to output gap detection trigger
3. Add gap reporting to CI summary
4. Test full pipeline in staging branch

**Dependencies:**
- Workflow → calls `detect_test_gaps.R` → calls `generate_tests.R`
- Requires GitHub Actions secrets (API key for cassette recording)

**Outcome:** Automated end-to-end pipeline

**Estimated effort:** 2-3 days

### Phase 4: Cassette Management (Cleanup and Quality)

**Prerequisites:** Phase 3 complete, tests running in CI

**Tasks:**
1. Create `dev/cleanup_cassettes.R` (deletion utility)
2. Review 673 untracked cassettes, delete bad ones
3. Re-run tests to re-record clean cassettes
4. Commit clean cassettes

**Dependencies:**
- Requires test failures to identify bad cassettes
- Needs API key for re-recording

**Outcome:** Clean cassette set, quality standards established

**Estimated effort:** 2-3 days

### Phase 5: Documentation and Refinement (Polish)

**Prerequisites:** Phase 4 complete, pipeline proven in production

**Tasks:**
1. Document test generation workflow in CLAUDE.md
2. Add CI workflow documentation (README for workflows)
3. Create troubleshooting guide for test failures
4. Refine test generator based on edge cases

**Outcome:** Production-ready, documented system

**Estimated effort:** 1-2 days

### Total Timeline

**Estimated:** 10-15 days for full integration

**Critical path:**
Phase 1 (blockers) → Phase 2 (components) → Phase 3 (CI) → Phase 4 (cassettes)

**Parallelizable:**
- Documentation can start in Phase 2
- Cassette cleanup can start early if test generation is manual

**Risks:**
- Stub generator fixes may reveal deeper issues (add 2-3 days)
- CI workflow debugging can be time-consuming (add 1-2 days)
- Bad cassette cleanup may take longer if many need manual review (add 2-3 days)

## New vs Modified Components

### Modified Components

| Component | File | Change Type | Lines Changed |
|-----------|------|-------------|---------------|
| Test Generator v2 | `tests/testthat/tools/helper-test-generator-v2.R` | **Fix** parameter type detection, **Add** tidy parameter reading | ~50 lines modified, ~30 lines added |
| Function Metadata Extractor | `tests/testthat/tools/helper-function-metadata.R` | **Add** `tidy` parameter extraction to `extract_generic_request_info()` | ~20 lines added |
| Stub Generator | `dev/generate_stubs.R` | **Add** GITHUB_OUTPUT for gap detection trigger | ~10 lines added |

### New Components

| Component | File | Purpose | Lines Estimated |
|-----------|------|---------|-----------------|
| Test Gap Detector | `dev/detect_test_gaps.R` | Scan R/ for functions without tests, output list | ~100 lines |
| Batch Test Orchestrator | `dev/generate_tests.R` | Generate tests for multiple functions, wrap test-generator-v2 | ~150 lines |
| Cassette Cleanup Script | `dev/cleanup_cassettes.R` | Delete cassettes by pattern or function name | ~80 lines |
| CI Test Generation Workflow | `.github/workflows/generate-tests.yml` | Automate detection → generation → commit flow | ~120 lines YAML |

### Unchanged Components (Zero Modifications)

| Component | Rationale |
|-----------|-----------|
| Stub generation pipeline (`dev/endpoint_eval/`) | Already stable (v1.9), comprehensive tests, lifecycle guards work |
| Generic request templates (`R/z_generic_request.R`) | Core infrastructure, no changes needed |
| VCR configuration (`tests/testthat/helper-vcr.R`) | Simple config, works correctly |
| CI test workflows (test-coverage.yml, R-CMD-check.yml) | Coverage enforcement and R CMD check don't need changes |

## References and Sources

**R package testing best practices:**
- [Getting started with vcr](https://cran.r-project.org/web/packages/vcr/vignettes/vcr.html) - Official vcr documentation for cassette management
- [Managing cassettes | HTTP testing in R](https://books.ropensci.org/http-testing/managing-cassettes.html) - rOpenSci guide to VCR cassette organization
- [Package 'vcr' CRAN](https://cran.r-project.org/web/packages/vcr/vcr.pdf) - vcr package reference manual

**Project-specific context:**
- `TODO.md` lines 23-33: Test infrastructure blockers (tidy mismatches, parameter type errors, 673 bad cassettes)
- `.planning/PROJECT.md`: Stub generation pipeline architecture (v1.0-v1.9 history)
- `dev/generate_stubs.R`: Existing orchestration pattern for stub generation
- `tests/testthat/tools/helper-test-generator-v2.R`: Current test generation logic (needs fixes)

**Key architectural decisions:**
- Detection-then-generation pattern avoids overwriting manual tests
- Metadata-driven generation prevents parameter type mismatches
- Cassette-per-test-variant enables selective re-recording
- Lifecycle protection guards prevent stable function overwrites
- Two-phase cassette recording separates initial capture from quality validation
