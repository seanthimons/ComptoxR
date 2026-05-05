---
phase: 35-shared-helper-layer-validation
reviewed: 2026-04-22T20:08:45Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - R/eco_lifestage_patch.R
  - dev/lifestage/validate_35.R
  - tests/testthat/test-eco_lifestage_gate.R
findings:
  critical: 1
  warning: 1
  info: 2
  total: 4
status: issues_found
---

# Phase 35: Code Review Report

**Reviewed:** 2026-04-22T20:08:45Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Phase 35 added tryCatch resilience to the NVS SPARQL and OLS4 REST HTTP adapters in `eco_lifestage_patch.R`, changed the NVS empty-bindings path from `cli_abort` to `cli_warn`, added an OLS4 prefix post-filter (`startsWith`), added a PROV-02 unit test for NVS failure, and created a validation script (`validate_35.R`).

The tryCatch wrappers and OLS4 prefix filter are structurally correct. However, there is one critical bug: the NVS error/empty-bindings paths return a zero-column tibble (`tibble::tibble()`) that will crash the downstream `.eco_lifestage_query_nvs()` filter when it references missing columns. The existing unit test masks this bug by mocking at the wrong level, returning a schema-conformant empty tibble instead of what the real error path produces. There is also a missing unit test for OLS4 failure resilience.

## Critical Issues

### CR-01: NVS error path returns zero-column tibble causing downstream crash in `.eco_lifestage_query_nvs()`

**File:** `R/eco_lifestage_patch.R:481` (also line 487)
**Issue:** When `.eco_lifestage_nvs_index()` encounters an HTTP error (line 461-478) or receives empty SPARQL bindings (line 484-488), it returns `tibble::tibble()` -- a tibble with zero columns and zero rows. The caller `.eco_lifestage_query_nvs()` at line 599 passes this zero-column tibble into a `dplyr::filter()` that references `.data$source_term_label` and `.data$candidate_aliases`. Since these columns do not exist in a zero-column tibble, `dplyr::filter` throws: `Column 'source_term_label' not found in '.data'`. This means the NVS tryCatch resilience is incomplete -- the error is caught inside `nvs_index`, but then a *new* error is raised in `query_nvs`, which propagates up uncaught and aborts the entire resolution run.

The unit test at `test-eco_lifestage_gate.R:564` masks this bug because it mocks `.eco_lifestage_nvs_index` to return a schema-conformant 8-column empty tibble (lines 565-574), not the zero-column tibble that the real error path produces.

**Fix:** Add an early return guard in `.eco_lifestage_query_nvs()` after fetching the index, checking for zero rows before filtering. This is the minimal fix; alternatively, the error paths in `.eco_lifestage_nvs_index()` could return a typed empty tibble.

Option A -- guard in `query_nvs` (preferred, defense-in-depth):
```r
# In .eco_lifestage_query_nvs(), after line 590:
.eco_lifestage_query_nvs <- function(term) {
  index <- .eco_lifestage_nvs_index()
  if (nrow(index) == 0) {
    return(tibble::tibble())
  }
  # ... rest of function
}
```

Option B -- return typed empty tibble from error paths in `nvs_index`:
```r
# Replace tibble::tibble() at lines 481 and 487 with a typed empty index:
nvs_empty <- tibble::tibble(
  source_provider = character(), source_ontology = character(),
  source_term_id = character(), source_term_label = character(),
  source_term_definition = character(), source_release = character(),
  source_match_method = character(), candidate_aliases = character()
)
return(nvs_empty)
```

Both options should be applied for belt-and-suspenders safety.

## Warnings

### WR-01: No unit test for OLS4 failure resilience

**File:** `tests/testthat/test-eco_lifestage_gate.R`
**Issue:** Phase 35 added a `tryCatch` wrapper to `.eco_lifestage_query_ols4()` (lines 522-542 of the patch file), but no corresponding unit test was added to the testthat suite to verify that OLS4 HTTP failures emit a warning and return an empty tibble. The NVS failure path has a proper unit test (lines 564-595), but OLS4 failure is only exercised in the dev validation script (`validate_35.R` section 6), which mocks at the function level and does not test the actual `tryCatch` path.

**Fix:** Add a test parallel to "NVS failure emits warning and returns empty tibble" that mocks at the HTTP adapter level (e.g., using `httr2::req_perform` failure or a mock that throws) to verify `query_ols4` returns an empty tibble with a warning:

```r
test_that("OLS4 failure emits warning and returns empty tibble", {
  warned <- FALSE
  result <- withCallingHandlers(
    testthat::with_mocked_bindings(
      req_perform = function(...) stop("connection refused"),
      .package = "httr2",
      .eco_lifestage_query_ols4("adult", "UBERON")
    ),
    warning = function(w) {
      if (grepl("OLS4 endpoint unreachable", conditionMessage(w))) {
        warned <<- TRUE
      }
      invokeRestart("muffleWarning")
    }
  )
  testthat::expect_true(warned)
  testthat::expect_s3_class(result, "tbl_df")
  testthat::expect_equal(nrow(result), 0L)
})
```

## Info

### IN-01: NVS failure test mocks at wrong abstraction level

**File:** `tests/testthat/test-eco_lifestage_gate.R:564-595`
**Issue:** The "NVS failure emits warning and returns empty tibble" test mocks `.eco_lifestage_nvs_index` rather than the HTTP layer. The mock returns a schema-conformant 8-column empty tibble, which is not what the real error handler produces (zero-column `tibble::tibble()`). This means the test validates downstream behavior with the wrong input shape. After fixing CR-01, consider also adding a test that mocks at the HTTP level (similar to the OLS4 suggestion in WR-01) to validate the full error path end-to-end.

**Fix:** After CR-01 is fixed, add a complementary test that mocks `httr2::req_perform` to throw an error, then verifies that `.eco_lifestage_query_nvs()` returns an empty tibble with a warning emitted.

### IN-02: Validation script (validate_35.R) uses `testthat::with_mocked_bindings` outside test context

**File:** `dev/lifestage/validate_35.R:124` (also line 156)
**Issue:** The validation script calls `testthat::with_mocked_bindings()` outside of a testthat test context (it runs via `Rscript`). While this works in practice with `devtools::load_all()`, it couples a dev validation script to the testthat package. This is a minor coupling concern, not a bug -- the script functions correctly. Noted for awareness only.

**Fix:** No action required. If desired in the future, the mock sections could use `local()` + environment manipulation instead of `with_mocked_bindings`.

---

_Reviewed: 2026-04-22T20:08:45Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
