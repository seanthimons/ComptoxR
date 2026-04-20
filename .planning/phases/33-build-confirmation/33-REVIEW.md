---
phase: 33-build-confirmation
reviewed: 2026-04-20T22:38:09Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - dev/lifestage/confirm_gate.R
  - tests/testthat/test-eco_lifestage_gate.R
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 33: Code Review Report

**Reviewed:** 2026-04-20T22:38:09Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed two test artifacts for the ECOTOX lifestage build gate: a dev-only confirmation script (`dev/lifestage/confirm_gate.R`) and a formal testthat regression test (`tests/testthat/test-eco_lifestage_gate.R`). Both exercise the same gate logic -- abort on truly unknown lifestage terms, warn-and-quarantine on keyword-classifiable terms.

The code is well-structured overall. Both files use proper cleanup patterns (`on.exit` in the dev script, `withr::defer` in the testthat file), correct DuckDB single-writer handling (closing cached connections before opening test connections), and appropriate skip guards for the database dependency. No security issues or critical bugs were found.

One warning-level gap was identified: the testthat test for the abort scenario does not verify the error message content, making it a weaker regression test than the dev script for the same scenario. Two info-level duplication concerns were noted.

## Warnings

### WR-01: Testthat abort test does not assert on error message content

**File:** `tests/testthat/test-eco_lifestage_gate.R:231-234`
**Issue:** The `expect_error(run_gate_logic(con), class = "rlang_error")` assertion only checks that an error of class `rlang_error` is raised. It does not verify that the error message mentions "Xylophage" or contains the expected diagnostic text ("lifestage dictionary is incomplete"). By contrast, the dev script (`confirm_gate.R:305-309`) explicitly asserts that the abort message mentions "Xylophage". If a future code change causes a different `rlang_error` to be thrown (e.g., a DBI connection error wrapped in `cli_abort`), this test would pass spuriously.

**Fix:** Add a `regexp` argument to `expect_error` to match on the expected message content:
```r
expect_error(
  run_gate_logic(con),
  regexp = "Xylophage",
  class = "rlang_error"
)
```

## Info

### IN-01: Classifier function and dictionary duplicated across three files

**File:** `dev/lifestage/confirm_gate.R:76-111` and `tests/testthat/test-eco_lifestage_gate.R:12-44`
**Issue:** The `.classify_lifestage_keywords()` function is defined identically in both reviewed files and also in the canonical source at `inst/ecotox/ecotox_build.R:975-1012`. The `life_stage` dictionary tibble (roughly 100 rows) is likewise triplicated. If any regex pattern or dictionary entry changes in the canonical source, both test copies must be updated manually -- drift is a real maintenance risk.

**Fix:** Consider extracting the classifier and dictionary into an internal utility (e.g., `R/lifestage_utils.R`, unexported) that can be sourced by `ecotox_build.R` and referenced by both test files via `ComptoxR:::.classify_lifestage_keywords()`. Alternatively, if inlining is intentional for isolation, add a comment at the top of each copy referencing the canonical source location so future editors know to sync changes.

### IN-02: Gate logic duplicated inline in dev confirmation script

**File:** `dev/lifestage/confirm_gate.R:268-291` and `dev/lifestage/confirm_gate.R:326-347`
**Issue:** The gate logic (query DB, compute unmapped, classify, abort-or-quarantine) is written inline twice in the dev script -- once for Scenario A (wrapped in `tryCatch`) and once for Scenario B (bare). The testthat file avoids this by extracting it into `run_gate_logic()` (line 190). The dev script could use the same pattern for consistency and to reduce maintenance surface.

**Fix:** Define a `run_gate_logic(con)` helper in the dev script (similar to the testthat file) and call it from both scenarios:
```r
# At top of Section 3, define once:
run_gate_logic <- function(con) {
  db_lifestages <- DBI::dbGetQuery(
    con, "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
  )$description
  unmapped <- setdiff(db_lifestages, life_stage$org_lifestage)
  if (length(unmapped) > 0) {
    keyword_mapped <- .classify_lifestage_keywords(unmapped)
    truly_unknown <- unmapped[keyword_mapped$harmonized_life_stage == "Other/Unknown"]
    if (length(truly_unknown) > 0) {
      cli::cli_abort(c(
        "ECOTOX lifestage dictionary is incomplete.",
        "i" = "{length(truly_unknown)} lifestage(s) could not be classified:",
        "*" = "{truly_unknown}"
      ))
    }
    cli::cli_alert_warning("{length(unmapped)} classified via keyword fallback.")
    DBI::dbWriteTable(con, "lifestage_review", keyword_mapped, overwrite = TRUE)
  }
}

# Scenario A:
gate_result <- tryCatch(run_gate_logic(eco_con), error = function(e) ...)

# Scenario B:
run_gate_logic(eco_con)
```

---

_Reviewed: 2026-04-20T22:38:09Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
