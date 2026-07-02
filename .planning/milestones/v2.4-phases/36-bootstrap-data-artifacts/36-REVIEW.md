---
phase: 36-bootstrap-data-artifacts
type: code-review
depth: standard
status: findings
files_reviewed: 3
files_reviewed_list:
  - tests/testthat/test-eco_lifestage_data.R
  - dev/lifestage/validate_36.R
  - dev/lifestage/refresh_baseline.R
date: 2026-04-23
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
---

# Phase 36: Code Review Report

**Reviewed:** 2026-04-23
**Depth:** standard
**Files Reviewed:** 3
**Status:** findings

## Summary

The Phase 36 deliverables are solid overall. The CI test gate correctly enforces schema integrity and the cross-check invariant (every resolved baseline key must have a derivation partner). The dev scripts are well-structured with clear section headers and appropriate use of `cli` messaging. Two warnings are raised: a missing regression test for the specific GO:0040007 contamination that motivated the phase, and a missing `skip_if_not_installed("readr")` guard. Two informational items note minor style/robustness improvements.

## Warnings

### WR-01: Missing CI regression test for GO:0040007 contamination

**File:** `tests/testthat/test-eco_lifestage_data.R`
**Issue:** Phase 36 was specifically motivated by GO:0040007 (growth biological process) contaminating the baseline CSV. The validation script `validate_36.R` (line 50) checks for this contamination, but the CI test file does not. If GO:0040007 rows are re-introduced (e.g., by a future resolver change), the CI gate will not catch it. The cross-check gate (line 56) only verifies that resolved keys have derivation partners -- it would pass even if GO:0040007 rows existed, as long as they also appeared in the derivation CSV.
**Fix:** Add a dedicated test block:
```r
test_that("lifestage_baseline.csv has no GO:0040007 contamination", {
  path <- system.file(
    "extdata", "ecotox", "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_baseline.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
  go_rows <- df[!is.na(df$source_term_id) & df$source_term_id == "GO:0040007", ]
  testthat::expect_equal(
    nrow(go_rows), 0L,
    info = "GO:0040007 (growth) is a biological process, not a life stage"
  )
})
```

### WR-02: Test uses `readr::read_csv()` without `skip_if_not_installed("readr")`

**File:** `tests/testthat/test-eco_lifestage_data.R:15`
**Issue:** `readr` is listed in `Suggests`, not `Imports`. All five test blocks call `readr::read_csv()` directly. If `readr` is not installed, tests will error rather than skip gracefully. The codebase already uses `skip_if_not_installed("pROC")` in `test-genra_uncertainty.R:83` for the same pattern.
**Fix:** Add at the top of the file (before the first `test_that`), or within each test block:
```r
testthat::skip_if_not_installed("readr")
```
Alternatively, place it once in a `setup()` block or at the top of the file outside `test_that()` if using testthat 3e with file-level skips.

## Info

### IN-01: `expect_equal` `label` argument used unconventionally for error context

**File:** `tests/testthat/test-eco_lifestage_data.R:83-94`
**Issue:** The `label` argument to `expect_equal` is used to inject a diagnostic message listing the gap keys. In testthat 3.x, `label` replaces the description of the `object` parameter in the failure output (e.g., `"3 resolved baseline key(s)..." (actual) not equal to 0L (expected)`). This works but is unconventional. The `info` argument is the idiomatic way to attach supplementary context to a failure message.
**Fix:** Replace `label` with `info`:
```r
testthat::expect_equal(
  nrow(gaps),
  0L,
  info = paste0(
    nrow(gaps),
    " resolved baseline key(s) have no derivation partner: ",
    paste(
      unique(paste0(gaps$source_ontology, ":", gaps$source_term_id)),
      collapse = ", "
    )
  )
)
```

### IN-02: `reproductive_stage = NA` uses bare NA instead of typed `NA`

**File:** `dev/lifestage/refresh_baseline.R:86`
**Issue:** In the proposals `mutate()`, `harmonized_life_stage` uses `NA_character_` (correctly typed), but `reproductive_stage` uses bare `NA`. Since the target column in the derivation CSV is logical (`TRUE`/`FALSE`), bare `NA` happens to default to `NA` (logical) in R, so this is correct by coincidence. For consistency with the `NA_character_` on the preceding line and to make the intent explicit, use the typed variant.
**Fix:** Change line 86 to:
```r
reproductive_stage = NA,
```
This is already logically correct (bare `NA` is `logical` in R). No change required, but for explicitness consider:
```r
reproductive_stage = NA,
```
Since bare `NA` is `logical` by default in R, this is actually fine as-is. The note is purely about consistency with the `NA_character_` on the adjacent line.

---

_Reviewed: 2026-04-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
