---
phase: 34-teardown
reviewed: 2026-04-22T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - R/eco_lifestage_patch.R
  - R/eco_functions.R
  - dev/lifestage/purge_and_rebuild.R
  - data-raw/ecotox.R
  - inst/ecotox/ecotox_build.R
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 34: Code Review Report

**Reviewed:** 2026-04-22
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Phase 34 removed v2.3 regex-first lifestage artifacts and introduced a 926-line
`R/eco_lifestage_patch.R` with a 14-function internal library for ontology-backed
lifestage resolution (OLS4/UBERON, OLS4/PO, NVS S11). The design is coherent: a
cache/baseline/live tiered refresh strategy, schema-validated CSV persistence,
and a derivation-map join to produce `harmonized_life_stage`. The eco_functions.R
query layer now joins `lifestage_dictionary` cleanly. No security vulnerabilities
or data-loss conditions were found.

Three logic bugs were identified — one of which (the year-duration arm missing in
the shipped `inst/ecotox/ecotox_build.R`) silently produces wrong duration
conversions for year-unit observations. Two additional logic issues in
`eco_lifestage_patch.R` will cause wrong behavior in edge cases.

---

## Warnings

### WR-01: Year-duration conversion arm missing in installed build script

**File:** `inst/ecotox/ecotox_build.R:563-570`

**Issue:** The `conversion_factor_duration` `case_when` block in the installed
build script is missing the `year` arm entirely. The canonical source copy at
`data-raw/ecotox.R:570` correctly includes:

```r
stringr::str_detect(tolower(description), "year") ~ 24 * 365.2425,
```

Because the installed copy falls through to `.default = 1`, year-unit
observations receive a conversion factor of 1 hour instead of 8765.82 hours.
Any duration-based filtering (e.g., chronic study duration checks in
`dict_test_result_duration`) computed against annual studies will be off by
roughly 3 orders of magnitude. The two files are supposed to be in sync; the
`data-raw/` version was updated but the `inst/` version was not.

**Fix:**
```r
# inst/ecotox/ecotox_build.R, inside conversion_factor_duration case_when
stringr::str_detect(tolower(description), "month") ~ 24 * 30.43685,
stringr::str_detect(tolower(description), "year") ~ 24 * 365.2425,   # ADD THIS LINE
.default = 1
```

---

### WR-02: `!nrow(accepted)` treats any non-zero integer as truthy — should be `nrow(accepted) == 0`

**File:** `R/eco_lifestage_patch.R:632`

**Issue:** The guard is written as:

```r
if (!nrow(accepted)) {
```

In R, `!nrow(x)` evaluates to `TRUE` only when `nrow(x) == 0` because `!0L` is
`TRUE` and `!n` for any positive integer is `FALSE`. While this produces the
correct boolean for the two states (0 vs positive), it is semantically
non-idiomatic and would silently break if `nrow()` ever returned `NA` (which
DuckDB-backed lazy frames can do in error scenarios). More importantly, using
`!nrow()` as a truthiness check is confusing to maintainers who may read it as
"no rows", fail to realize it only works because R coerces integers to logical,
and accidentally replicate the pattern somewhere it does not hold. The correct
idiom is an explicit comparison.

**Fix:**
```r
if (nrow(accepted) == 0) {
```

---

### WR-03: `baseline_matches` type mismatch — `identical()` comparing a character vector to a scalar string

**File:** `R/eco_lifestage_patch.R:299`

**Issue:** `baseline_releases` is the result of:

```r
baseline_releases <- unique(stats::na.omit(baseline$ecotox_release))
```

This produces a character vector of length 0, 1, or more. The comparison is:

```r
baseline_matches <- identical(baseline_releases, ecotox_release)
```

`ecotox_release` is a single character scalar. `identical()` requires both
sides to be the exact same type and length. If the baseline CSV has rows for
exactly one release and it matches, `identical(character(1), character(1))`
will correctly return `TRUE`. But if `baseline_releases` has zero elements
(all NA release values) or more than one element (mixed-release baseline),
`identical()` returns `FALSE` even when the target release is present among
the entries. Consequently a valid same-release baseline is incorrectly rejected
when any rows are missing `ecotox_release`, causing the code to fall through to
a live network call instead of using the baseline. This is inconsistent with the
analogous check in `.eco_lifestage_validate_cache()` (lines 210-216) which
handles the multi-release case differently.

**Fix:**
```r
baseline_matches <- length(baseline_releases) == 1 &&
  identical(baseline_releases, ecotox_release)
```

This mirrors the guard in `.eco_lifestage_validate_cache()` at line 210-211.

---

## Info

### IN-01: `.eco_lifestage_load_seed_cache()` fallback recursion carries unbounded risk

**File:** `R/eco_lifestage_patch.R:316-317` and `R/eco_lifestage_patch.R:330-331`

**Issue:** When `force = TRUE` and the strict mode (`"cache"` or `"baseline"`)
cannot be satisfied, the function recurses into itself with `refresh = "auto"`:

```r
return(.eco_lifestage_load_seed_cache(ecotox_release, refresh = "auto", force = FALSE))
```

This is a single-level recursion (the recursive call passes `force = FALSE` so
it cannot recurse again), so there is no infinite loop. However, it is
non-obvious and the `force` parameter meaning changes mid-call, which makes the
code harder to follow. Consider a named helper or a `repeat`/`break` loop to
make the fallback intent explicit. Not a bug in the current code but worth
flagging for maintainability.

---

### IN-02: `purge_and_rebuild.R` opens two DuckDB connections to the same file without full shutdown between them

**File:** `dev/lifestage/purge_and_rebuild.R:26-37` and `51-52`

**Issue:** Step 1 drops tables using `con`, then calls `DBI::dbDisconnect(con, shutdown = TRUE)` and `.eco_close_con()`. Step 2 calls `.eco_patch_lifestage()` which opens its own connection. Step 3 then opens `con2` with `read_only = TRUE`. This sequence is correct on Linux/macOS. On Windows with DuckDB, `shutdown = TRUE` disposes the engine instance, but WAL files can persist briefly. The comment at line 48-49 explicitly calls this out. The `shutdown = FALSE` on `con2` is the right mitigation, but if `.eco_patch_lifestage()` itself were to leave a connection open (its `on.exit` includes `.eco_close_con()`), the schema assertion would fail with a lock error. This is a fragile but not currently broken pattern; annotate the dependency explicitly.

---

### IN-03: `eco_functions.R` uses `field` from `match.arg()` directly in SQL string concatenation

**File:** `R/eco_functions.R:213`

**Issue:** The `eco_species()` function builds a SQL string via:

```r
sql <- paste0("SELECT * FROM species WHERE ", field, " ILIKE ?")
```

The comment at line 212 notes `field` is from `match.arg()` — making it safe
against injection since it is constrained to `c("common_name", "latin_name",
"eco_group")`. This is correct. However, the comment is the only thing
preventing a future maintainer from adding a user-supplied field without going
through `match.arg()`. Consider using a lookup-table approach or an explicit
allowlist assertion so the safety guarantee is structural, not comment-dependent.
This is low priority given the existing guard works correctly.

---

_Reviewed: 2026-04-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
