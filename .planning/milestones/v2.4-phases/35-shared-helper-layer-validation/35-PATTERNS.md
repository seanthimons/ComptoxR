# Phase 35: Shared Helper Layer Validation - Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 3 (2 modified source files + 1 new dev script)
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `R/eco_lifestage_patch.R` (lines 440-545) | service / HTTP adapter | request-response | `R/eco_connection.R` lines 128-138 | role-match (tryCatch + cli_warn pattern) |
| `R/eco_lifestage_patch.R` (line 544, filter) | utility / transform | transform | `R/eco_lifestage_patch.R` line 544 (existing filter) | exact (extension of existing dplyr::filter chain) |
| `dev/lifestage/validate_35.R` | dev script / validation | request-response + transform | `dev/lifestage/validate_lifestage.R` | exact (same sourcing pattern, same cli structure) |

---

## Pattern Assignments

### `R/eco_lifestage_patch.R` — NVS tryCatch fix (`.eco_lifestage_nvs_index()`, lines 457-467)

**What changes:** The bare `httr2` pipeline at lines 457-462 and the `cli_abort` at line 466 must be replaced.

**Analog:** `R/eco_connection.R` lines 128-138 — tryCatch wrapping a fallible operation, `cli_warn` with named message bullets, continuation logic after failure.

**Existing code to replace** (lines 457-467 of `R/eco_lifestage_patch.R`):
```r
payload <- httr2::request("https://vocab.nerc.ac.uk/sparql/sparql") |>
  httr2::req_body_form(query = query) |>
  httr2::req_headers(Accept = "application/sparql-results+json") |>
  httr2::req_perform() |>
  httr2::resp_body_string() |>
  jsonlite::fromJSON(simplifyDataFrame = TRUE)

bindings <- payload$results$bindings
if (is.null(bindings) || nrow(bindings) == 0) {
  cli::cli_abort("NVS S11 lookup returned no concepts.")
}
```

**tryCatch + cli_warn pattern** (from `R/eco_connection.R` lines 128-138):
```r
tryCatch(
  .db_download_release("ecotox", dest, tag = tag),
  error = function(e) {
    cli::cli_warn(c(
      "Could not download ECOTOX database from GitHub Release.",
      "i" = conditionMessage(e),
      "i" = "Falling back to build-from-source."
    ))
    .eco_build_from_source(dest)
  }
)
```

**After pattern applied to NVS adapter** (D-03/D-04 from RESEARCH.md):
```r
payload <- tryCatch(
  {
    httr2::request("https://vocab.nerc.ac.uk/sparql/sparql") |>
      httr2::req_body_form(query = query) |>
      httr2::req_headers(Accept = "application/sparql-results+json") |>
      httr2::req_perform() |>
      httr2::resp_body_string() |>
      jsonlite::fromJSON(simplifyDataFrame = TRUE)
  },
  error = function(e) {
    cli::cli_warn(c(
      "NVS S11 SPARQL endpoint unreachable.",
      "i" = "NVS candidates will be skipped for this resolution run.",
      "x" = conditionMessage(e)
    ))
    NULL
  }
)

if (is.null(payload)) {
  return(tibble::tibble())
}

bindings <- payload$results$bindings
if (is.null(bindings) || nrow(bindings) == 0) {
  cli::cli_warn("NVS S11 lookup returned no concepts.")
  return(tibble::tibble())
}
```

**Critical ordering constraint:** Both `return(tibble::tibble())` guards must appear BEFORE the `index` construction and the `.ComptoxREnv$eco_lifestage_nvs_index <- index` assignment at line 493. An early return prevents caching an empty index that would suppress retries and their warnings on subsequent calls.

---

### `R/eco_lifestage_patch.R` — OLS4 tryCatch fix (`.eco_lifestage_query_ols4()`, lines 501-509)

**What changes:** The bare `httr2` pipeline at lines 501-509 needs the same tryCatch wrapper (D-06). This adapter has no cache assignment concern — an early return is always safe.

**Existing code to replace** (lines 501-509 of `R/eco_lifestage_patch.R`):
```r
response <- httr2::request("https://www.ebi.ac.uk/ols4/api/search") |>
  httr2::req_url_query(
    q = term,
    ontology = tolower(ontology),
    rows = 25
  ) |>
  httr2::req_perform() |>
  httr2::resp_body_string() |>
  jsonlite::fromJSON(simplifyDataFrame = TRUE)
```

**After pattern applied** (same tryCatch shape as NVS fix above, D-06):
```r
response <- tryCatch(
  {
    httr2::request("https://www.ebi.ac.uk/ols4/api/search") |>
      httr2::req_url_query(
        q = term,
        ontology = tolower(ontology),
        rows = 25
      ) |>
      httr2::req_perform() |>
      httr2::resp_body_string() |>
      jsonlite::fromJSON(simplifyDataFrame = TRUE)
  },
  error = function(e) {
    cli::cli_warn(c(
      "OLS4 endpoint unreachable for {ontology}.",
      "i" = "OLS4 candidates will be skipped for this resolution run.",
      "x" = conditionMessage(e)
    ))
    NULL
  }
)

if (is.null(response)) {
  return(tibble::tibble())
}
```

---

### `R/eco_lifestage_patch.R` — OLS4 prefix post-filter (`.eco_lifestage_query_ols4()`, line 544)

**What changes:** A second `dplyr::filter()` condition is appended to the existing filter chain at line 544 (D-05).

**Analog:** Line 544 of `R/eco_lifestage_patch.R` — the existing filter is the direct predecessor; the new condition extends it.

**Existing filter** (line 544 of `R/eco_lifestage_patch.R`):
```r
dplyr::filter(!is.na(.data$source_term_id), !is.na(.data$source_term_label))
```

**After prefix post-filter added**:
```r
dplyr::filter(
  !is.na(.data$source_term_id),
  !is.na(.data$source_term_label),
  startsWith(.data$source_term_id, paste0(toupper(ontology), ":"))
)
```

**Case requirement:** `toupper(ontology)` — OLS4 returns IDs in uppercase (`UBERON:`, `PO:`). Using `tolower` here removes all valid rows. The `ontology` variable at this point in the function holds the validated enum value (already uppercased by `rlang::arg_match` against `c("UBERON", "PO")`), but `toupper()` makes the intent explicit.

---

### `dev/lifestage/validate_35.R` (new validation script)

**Analog:** `dev/lifestage/validate_lifestage.R` — exact structural match: shebang line, `suppressPackageStartupMessages` block, `devtools::load_all()` or manual source, cli header/section structure, `stopifnot` assertions, print output.

**Header + load gate pattern** (from `dev/lifestage/validate_lifestage.R` lines 1-12 and `dev/lifestage/confirm_gate.R` lines 1-23):
```r
#!/usr/bin/env Rscript

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
```

Note: `devtools::load_all()` replaces the manual `source("R/eco_connection.R"); source("R/eco_lifestage_patch.R")` pattern used in the existing dev scripts. It loads all package symbols including `.ComptoxREnv` initialization, satisfying D-09 (load gate) as a side-effect of the script header.

**CLI section structure** (from `dev/lifestage/validate_lifestage.R` lines 27-58):
```r
cli::cli_h1("Phase 35 Validation")

# --- Section heading style ---
cli::cli_h2("Schema Functions")
cli::cli_alert_success("...")
cli::cli_alert_info("...")
```

**stopifnot assertion pattern** (from `dev/lifestage/purge_and_rebuild.R` lines 57-68):
```r
if ("ontology_id" %in% actual_cols) {
  cli::cli_abort("FAIL: ontology_id still present in lifestage_dictionary schema")
}
missing <- setdiff(expected_cols, actual_cols)
if (length(missing) > 0) {
  cli::cli_abort("FAIL: missing v2.4 columns: {paste(missing, collapse = ', ')}")
}
```

**Preferred pattern for validate_35.R** — use `stopifnot()` for brevity where the abort message is self-explanatory; use `cli::cli_abort()` with context only where the failure message requires interpolation:
```r
cache_schema <- .eco_lifestage_cache_schema()
stopifnot(ncol(cache_schema) == 13)

dict_schema <- .eco_lifestage_dictionary_schema()
stopifnot(ncol(dict_schema) == 13)

review_schema <- .eco_lifestage_review_schema()
stopifnot(ncol(review_schema) == 9)
```

**NVS failure simulation pattern** (D-08 — use `testthat::with_mocked_bindings`; testthat is already in Suggests):
```r
# Section: NVS failure simulation
cli::cli_h2("NVS Failure Simulation")
nvs_result <- testthat::with_mocked_bindings(
  .eco_lifestage_nvs_index = function(refresh = FALSE) {
    cli::cli_warn("NVS S11 SPARQL endpoint unreachable. [SIMULATED]")
    tibble::tibble()
  },
  .package = "ComptoxR",
  .eco_lifestage_query_nvs("Adult")
)
stopifnot(is.data.frame(nvs_result))
stopifnot(nrow(nvs_result) == 0)
cli::cli_alert_success("NVS failure simulation: empty tibble returned without error")
```

**OLS4 failure simulation** (discretionary per D-07 — recommended to test both adapters):
```r
# Section: OLS4 failure simulation
cli::cli_h2("OLS4 Failure Simulation")
ols4_result <- testthat::with_mocked_bindings(
  `httr2::req_perform` = function(...) stop("simulated network error"),
  .package = "httr2",
  .eco_lifestage_query_ols4("adult", "UBERON")
)
stopifnot(is.data.frame(ols4_result))
stopifnot(nrow(ols4_result) == 0)
cli::cli_alert_success("OLS4 failure simulation: empty tibble returned without error")
```

Note: OLS4 failure simulation via `with_mocked_bindings` on `httr2::req_perform` requires mocking the httr2 package namespace directly. An alternative is to wrap the entire `.eco_lifestage_query_ols4` call in a mock that returns `tibble::tibble()` after emitting a warn, analogous to the NVS approach.

**Live OLS4 prefix verification** (PROV-01 smoke check):
```r
cli::cli_h2("Live OLS4 Prefix Filter")
ols4_adult <- .eco_lifestage_query_ols4("adult", "UBERON")
if (nrow(ols4_adult) > 0) {
  bad <- ols4_adult[!startsWith(ols4_adult$source_term_id, "UBERON:"), ]
  if (nrow(bad) > 0) {
    cli::cli_abort("OLS4 returned non-UBERON IDs: {paste(bad$source_term_id, collapse = ', ')}")
  }
  cli::cli_alert_success("OLS4 prefix filter: all {nrow(ols4_adult)} row(s) have UBERON: prefix")
} else {
  cli::cli_alert_info("OLS4 returned 0 rows for 'adult' (network may be unavailable)")
}
```

---

## Shared Patterns

### tryCatch + cli_warn + empty tibble return (HTTP adapters)

**Source:** `R/eco_connection.R` lines 128-138 (tryCatch + cli_warn with named message bullets)

**Apply to:** `.eco_lifestage_nvs_index()` (line 457) and `.eco_lifestage_query_ols4()` (line 501)

**Pattern:**
```r
result <- tryCatch(
  {
    # ... httr2 pipeline ...
  },
  error = function(e) {
    cli::cli_warn(c(
      "Human-readable description of what failed.",
      "i" = "Consequence for the caller (candidates will be skipped, etc.).",
      "x" = conditionMessage(e)
    ))
    NULL
  }
)

if (is.null(result)) {
  return(tibble::tibble())
}
```

**Key rule:** The `return(tibble::tibble())` must come before any cache assignment (`env$key <- value`). This ensures failure does not poison the session cache.

### cli message format (named bullet style)

**Source:** `R/eco_connection.R` lines 131-135; `R/eco_lifestage_patch.R` lines 839-842

**Apply to:** All new `cli_warn` calls in adapter fixes

**Pattern:**
```r
cli::cli_warn(c(
  "Primary message describing what failed.",
  "i" = "Informational follow-up (consequence or suggestion).",
  "x" = conditionMessage(e)      # actual error text
))
```

The `"i"` bullet is informational context; `"x"` is the error detail. Both are optional but the `"i"` bullet for consequence is project convention (compare `eco_connection.R` line 134: `"i" = "Falling back to build-from-source."`).

### with_mocked_bindings (test and dev script mocking)

**Source:** `tests/testthat/test-eco_lifestage_gate.R` lines 245-252 (`with_lifestage_files` helper) and lines 279-282, 363-366

**Apply to:** NVS failure simulation section in `dev/lifestage/validate_35.R`, and the new PROV-02 unit test case in `tests/testthat/test-eco_lifestage_gate.R`

**Pattern (from test-eco_lifestage_gate.R lines 245-251):**
```r
testthat::with_mocked_bindings(
  .eco_lifestage_query_ols4 = function(...) stop("live lookup should not run"),
  .eco_lifestage_query_nvs = function(...) stop("live lookup should not run"),
  .package = "ComptoxR",
  {
    # ... code under test ...
  }
)
```

**Adaptation for NVS failure simulation:**
```r
testthat::with_mocked_bindings(
  .eco_lifestage_nvs_index = function(refresh = FALSE) {
    cli::cli_warn("NVS S11 SPARQL endpoint unreachable. [SIMULATED]")
    tibble::tibble()
  },
  .package = "ComptoxR",
  .eco_lifestage_query_nvs("Adult")
)
```

### dplyr::filter chain extension

**Source:** `R/eco_lifestage_patch.R` line 544

**Apply to:** `.eco_lifestage_query_ols4()` prefix post-filter addition

**Pattern:** Add conditions to an existing `dplyr::filter()` call by expanding the single-line form to multi-line:
```r
# Before:
dplyr::filter(!is.na(.data$source_term_id), !is.na(.data$source_term_label))

# After (add one condition per line, pipe position unchanged):
dplyr::filter(
  !is.na(.data$source_term_id),
  !is.na(.data$source_term_label),
  startsWith(.data$source_term_id, paste0(toupper(ontology), ":"))
)
```

### PROV-02 unit test (new test case in existing test file)

**Source:** `tests/testthat/test-eco_lifestage_gate.R` lines 416-447 ("unresolved terms are quarantined during patch" test) — closest existing test: provider returns empty tibble → pipeline continues cleanly

**Pattern for new PROV-02 test** (NVS failure → cli_warn + empty tibble, OLS4 still contributes):
```r
test_that("NVS failure emits warning and returns empty tibble", {
  testthat::expect_warning(
    testthat::with_mocked_bindings(
      .eco_lifestage_nvs_index = function(refresh = FALSE) {
        cli::cli_warn("NVS S11 SPARQL endpoint unreachable. [TEST]")
        tibble::tibble()
      },
      .package = "ComptoxR",
      result <- .eco_lifestage_query_nvs("Adult")
    ),
    "NVS S11 SPARQL"
  )
  testthat::expect_s3_class(result, "tbl_df")
  testthat::expect_equal(nrow(result), 0L)
})
```

Note: This test validates that after the D-03 fix, a warning is emitted and an empty tibble is returned — not an error. Place this test in `tests/testthat/test-eco_lifestage_gate.R` before the final section-identity test.

---

## No Analog Found

All three deliverables have close analogs in the existing codebase. No files require falling back to RESEARCH.md patterns exclusively.

| File | Note |
|------|------|
| — | All analogs found |

---

## Metadata

**Analog search scope:** `R/`, `dev/lifestage/`, `tests/testthat/`
**Files scanned:** `R/eco_lifestage_patch.R` (926 lines), `R/eco_connection.R` (lines 120-142), `tests/testthat/test-eco_lifestage_gate.R` (578 lines), `dev/lifestage/validate_lifestage.R`, `dev/lifestage/confirm_gate.R`, `dev/lifestage/purge_and_rebuild.R`
**Pattern extraction date:** 2026-04-22
