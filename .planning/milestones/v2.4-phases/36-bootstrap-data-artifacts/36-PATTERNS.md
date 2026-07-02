# Phase 36: Bootstrap Data Artifacts - Pattern Map

**Mapped:** 2026-04-23
**Files analyzed:** 6 (2 CSV artifacts + 4 new code files)
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `inst/extdata/ecotox/lifestage_baseline.csv` | data artifact | transform | `inst/extdata/ecotox/lifestage_baseline.csv` (self — targeted 3-row replacement) | exact |
| `inst/extdata/ecotox/lifestage_derivation.csv` | data artifact | CRUD | `inst/extdata/ecotox/lifestage_derivation.csv` (self — append 6 rows) | exact |
| `tests/testthat/test-eco_lifestage_data.R` | test | request-response | `tests/testthat/test-eco_lifestage_gate.R` | role-match |
| `dev/lifestage/validate_36.R` | utility/dev script | batch | `dev/lifestage/validate_35.R` | exact |
| `dev/lifestage/refresh_baseline.R` | utility/dev script | batch | `dev/lifestage/purge_and_rebuild.R` + `dev/lifestage/validate_lifestage.R` | role-match |
| `dev/lifestage/README.md` | documentation | — | none (new file type for this directory) | no-analog |

---

## Pattern Assignments

### `inst/extdata/ecotox/lifestage_baseline.csv` (data artifact, transform)

**Analog:** `R/eco_lifestage_patch.R` lines 240-249 (write pattern) + RESEARCH.md Code Examples

**Targeted replacement pattern** — load full file, mutate 3 rows in-memory, write back atomically. Never partial-write:

```r
# From eco_lifestage_patch.R:248 — canonical CSV write call
utils::write.csv(x, path, row.names = FALSE, na = "")
```

**Row format to match** (from `inst/extdata/ecotox/lifestage_baseline.csv` line 2):
```
"org_lifestage","source_provider","source_ontology","source_term_id","source_term_label",
"source_term_definition","source_release","source_match_method","source_match_status",
"candidate_rank","candidate_score","candidate_reason","ecotox_release"
```

**Replacement target filter** — filter by `source_term_id == "GO:0040007"` exactly (3 rows):
- "Exponential growth phase (log)", "Lag growth phase", "Stationary growth phase"
- Expected post-replacement `source_match_status`: `"unresolved"` (D-04)

**In-place replacement pattern** (from RESEARCH.md Code Examples):
```r
# Load full baseline into memory
baseline_path <- .eco_lifestage_baseline_path()
baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)

# Re-resolve the 3 rows, then dplyr::rows_update — do NOT regenerate all 139 rows (D-05)
baseline_updated <- dplyr::rows_update(
  baseline,
  re_resolved,
  by = "org_lifestage",
  unmatched = "ignore"
)

# Write entire tibble back — consistent quoting, NA as ""
utils::write.csv(baseline_updated, baseline_path, row.names = FALSE, na = "")
```

---

### `inst/extdata/ecotox/lifestage_derivation.csv` (data artifact, CRUD)

**Analog:** `inst/extdata/ecotox/lifestage_derivation.csv` (self — append 6 rows)

**Existing column schema** (line 1 of file):
```
"source_ontology","source_term_id","harmonized_life_stage","reproductive_stage","derivation_source"
```

**Existing row format example** (lines 2-10 of file):
```
"PO","PO:0000037","Adult",FALSE,"baseline_curated_source_id"
"PO","PO:0001016","Adult",FALSE,"baseline_curated_source_id"
"PO","PO:0009046","Adult",TRUE,"baseline_curated_source_id"
```

**6 rows to hand-author** (from RESEARCH.md Cross-Check Gaps table):

| source_ontology | source_term_id | harmonized_life_stage | reproductive_stage | derivation_source |
|-----------------|----------------|-----------------------|--------------------|-------------------|
| S11 | S1116 | Adult | FALSE | baseline_curated_source_id |
| S11 | S1122 | Egg/Embryo | FALSE | baseline_curated_source_id |
| S11 | S1106 | Egg/Embryo | FALSE | baseline_curated_source_id |
| S11 | S1128 | Larva | FALSE | baseline_curated_source_id |
| PO | PO:0000055 | Adult | TRUE | baseline_curated_source_id |
| PO | PO:0009010 | Egg/Embryo | FALSE | baseline_curated_source_id |

**Write pattern** — append rows manually in the CSV editor (or via R for atomic write):
```r
# From eco_lifestage_patch.R:248 — same canonical write used for all CSV artifacts
utils::write.csv(x, path, row.names = FALSE, na = "")
```

**Validation note:** `derivation_source` value for hand-authored rows uses `"baseline_curated_source_id"` — the existing pattern in the file (visible in every current row). PO:0000055 and PO:0009010 require curator sign-off before commit.

---

### `tests/testthat/test-eco_lifestage_data.R` (test, request-response)

**Analog:** `tests/testthat/test-eco_lifestage_gate.R`

**File header pattern** (lines 1-2 of test-eco_lifestage_gate.R):
```r
# Tests for source-backed ECOTOX lifestage patching
# -------------------------------------------------
```

**Pure CSV read — no package function calls in assertions** (Pitfall 5 from RESEARCH.md — hardcode expected columns, do not call `.eco_lifestage_cache_schema()`):
```r
# system.file() works in devtools::test() context after load_all()
baseline_path <- system.file(
  "extdata", "ecotox", "lifestage_baseline.csv",
  package = "ComptoxR"
)
derivation_path <- system.file(
  "extdata", "ecotox", "lifestage_derivation.csv",
  package = "ComptoxR"
)
baseline  <- readr::read_csv(baseline_path,  show_col_types = FALSE)
derivation <- readr::read_csv(derivation_path, show_col_types = FALSE)
```

**Anti-join test pattern** (from RESEARCH.md Pattern 1, with distinct() fix for Pitfall 6):
```r
test_that("every resolved baseline row has a derivation partner", {
  # ... (CSV reads above) ...
  resolved <- dplyr::filter(baseline, source_match_status == "resolved")
  # Use distinct() on keys only — multiple org_lifestage values share one key (Pitfall 6)
  resolved_keys <- dplyr::distinct(resolved, source_ontology, source_term_id)
  gaps <- dplyr::anti_join(
    resolved_keys,
    derivation,
    by = c("source_ontology", "source_term_id")
  )
  expect_equal(
    nrow(gaps), 0L,
    label = paste0(
      nrow(gaps), " resolved baseline key(s) have no derivation partner: ",
      paste(unique(paste0(gaps$source_ontology, ":", gaps$source_term_id)), collapse = ", ")
    )
  )
})
```

**Schema column count pattern** (from RESEARCH.md Pattern 2 — hardcoded vectors, not schema function calls):
```r
test_that("baseline CSV has 13 expected columns", {
  path <- system.file("extdata", "ecotox", "lifestage_baseline.csv", package = "ComptoxR")
  df   <- readr::read_csv(path, show_col_types = FALSE)
  expected_cols <- c(
    "org_lifestage", "source_provider", "source_ontology", "source_term_id",
    "source_term_label", "source_term_definition", "source_release",
    "source_match_method", "source_match_status", "candidate_rank",
    "candidate_score", "candidate_reason", "ecotox_release"
  )
  expect_equal(sort(names(df)), sort(expected_cols))
})

test_that("derivation CSV has 5 expected columns", {
  path <- system.file("extdata", "ecotox", "lifestage_derivation.csv", package = "ComptoxR")
  df   <- readr::read_csv(path, show_col_types = FALSE)
  expected_cols <- c(
    "source_ontology", "source_term_id",
    "harmonized_life_stage", "reproductive_stage", "derivation_source"
  )
  expect_equal(sort(names(df)), sort(expected_cols))
})
```

**test_that() pattern** from `test-eco_lifestage_gate.R` lines 260-306:
- No `describe()` blocks — flat `test_that()` calls throughout
- `testthat::expect_equal()` for equality, `testthat::expect_true()` for boolean
- `on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)` for DB cleanup (not applicable here — no DB calls in gate)
- No `skip_on_cran()` needed — pure file reads, CI-safe

**Quick run command:** `devtools::test(filter = "eco_lifestage_data")`

---

### `dev/lifestage/validate_36.R` (utility/dev script, batch)

**Analog:** `dev/lifestage/validate_35.R` (exact match — same phase validation pattern)

**File header pattern** (lines 1-6 of validate_35.R):
```r
#!/usr/bin/env Rscript
# Phase 36: Bootstrap Data Artifacts Validation
# Run from project root: Rscript dev/lifestage/validate_36.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
```

**Section structure pattern** (validate_35.R lines 10-15):
```r
cli::cli_h1("Phase 36 Validation")

cli::cli_h2("1. <Section Name>")
# ... checks ...
cli::cli_alert_success("<result message>")

cli::cli_h1("Phase 36 Validation Complete")
cli::cli_alert_success("All checks passed.")
```

**DB-optional guard pattern** (from validate_lifestage.R lines 13-19, adapted with D-07 warn-not-abort):
```r
db_path <- eco_path()
if (!file.exists(db_path)) {
  cli::cli_warn("ECOTOX DB not found at {.path {db_path}} — completeness check skipped.")
} else {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  # ... release check (D-07) and completeness anti-join (D-06) ...
}
```

**Release match abort pattern** (D-07 — mismatch → `cli_abort`):
```r
db_release       <- .eco_lifestage_release_id(con)
baseline_release <- unique(stats::na.omit(baseline$ecotox_release))
if (!identical(db_release, baseline_release)) {
  cli::cli_abort(
    "Release mismatch: DB={.val {db_release}}, baseline={.val {baseline_release}}"
  )
}
```

**Completeness anti-join pattern** (D-06, from RESEARCH.md Code Examples):
```r
db_terms <- DBI::dbGetQuery(
  con, "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
)$description

missing_from_baseline <- setdiff(db_terms, baseline$org_lifestage)
if (length(missing_from_baseline) == 0) {
  cli::cli_alert_success(
    "Completeness: all {length(db_terms)} DB terms present in baseline."
  )
} else {
  cli::cli_abort(
    "Baseline missing {length(missing_from_baseline)} DB term(s): {missing_from_baseline}"
  )
}
```

**Cross-check re-run pattern** (D-11 — validate_36.R re-runs D-10 assertions with verbose output):
```r
cli::cli_h2("2. Cross-Check Gate (D-10)")
resolved_keys <- baseline |>
  dplyr::filter(source_match_status == "resolved") |>
  dplyr::distinct(source_ontology, source_term_id)
gaps <- dplyr::anti_join(resolved_keys, derivation, by = c("source_ontology", "source_term_id"))
stopifnot(nrow(gaps) == 0)
cli::cli_alert_success(
  "Cross-check: {nrow(resolved_keys)} resolved key(s) all have derivation partners."
)
```

**stopifnot() pattern** (validate_35.R lines 14, 29, 37): Use `stopifnot()` for hard assertions; `cli_alert_success` to confirm each passing check.

---

### `dev/lifestage/refresh_baseline.R` (utility/dev script, batch)

**Analog:** `dev/lifestage/purge_and_rebuild.R` (script that calls internal helpers + DB) + `dev/lifestage/validate_lifestage.R` (DB connection pattern)

**File header pattern** (from purge_and_rebuild.R lines 1-15):
```r
#!/usr/bin/env Rscript
# Lifestage Baseline Refresh Script — run when a new ECOTOX release is installed.
# Run from project root: Rscript dev/lifestage/refresh_baseline.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
```

**DB connection + guard pattern** (purge_and_rebuild.R lines 15-19, validate_lifestage.R lines 13-19):
```r
db_path <- eco_path()
if (!file.exists(db_path)) {
  cli::cli_abort("ECOTOX DuckDB not found at {.path {db_path}}.")
}
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
```

**Release ID extraction pattern** (validate_lifestage.R line 21):
```r
ecotox_release <- .eco_lifestage_release_id(con)
```

**DB terms query pattern** (validate_lifestage.R lines 22-26):
```r
org_lifestages <- DBI::dbGetQuery(
  con,
  "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
)$description
```

**Resolve + write baseline pattern** (RESEARCH.md Code Examples — `.eco_lifestage_resolve_term()` loop + write):
```r
# Re-resolve each DB term via existing Phase-35 helper (D-13)
re_resolved <- purrr::map_dfr(
  org_lifestages,
  .eco_lifestage_resolve_term,
  ecotox_release = ecotox_release
)
utils::write.csv(re_resolved, .eco_lifestage_baseline_path(), row.names = FALSE, na = "")
cli::cli_alert_success("Baseline written: {nrow(re_resolved)} rows.")
```

**Derivation proposals — warn, do not abort** (D-16):
```r
# Identify new (unseen) source_term_ids not yet in derivation (D-14)
resolved_new <- re_resolved |>
  dplyr::filter(source_match_status == "resolved") |>
  dplyr::distinct(source_ontology, source_term_id)

derivation <- .eco_lifestage_derivation_map()
new_keys <- dplyr::anti_join(
  resolved_new, derivation,
  by = c("source_ontology", "source_term_id")
)

if (nrow(new_keys) > 0) {
  # Write to derivation_proposals.csv — NEVER to lifestage_derivation.csv (D-14)
  proposals_path <- file.path("dev", "lifestage", "derivation_proposals.csv")
  utils::write.csv(new_keys, proposals_path, row.names = FALSE, na = "")
  # D-16: cli_warn, not cli_abort — curator controls pacing
  cli::cli_warn(c(
    "{nrow(new_keys)} new resolved key(s) have no derivation partner.",
    "i" = "Review {.path {proposals_path}} and promote approved rows to {.path inst/extdata/ecotox/lifestage_derivation.csv}."
  ))
}
```

**Section headers pattern** (purge_and_rebuild.R lines 22, 41, 47):
```r
cli::cli_h1("Lifestage Baseline Refresh")
cli::cli_h2("Step 1: Fetch DB Terms")
# ...
cli::cli_h2("Step 2: Re-resolve All Terms")
# ...
cli::cli_h2("Step 3: Check Derivation Coverage")
# ...
cli::cli_alert_success("Refresh complete.")
```

---

### `dev/lifestage/README.md` (documentation)

**Analog:** None — no existing README in `dev/lifestage/`.

**Reference style:** See `LIFESTAGE_HARMONIZATION_PLAN2.md` for documentation tone and heading structure used in this subproject.

**Required content per D-15:**
- When to run (new ECOTOX release installed)
- Prerequisites: live OLS4/NVS API access, `ecotox.duckdb` present
- How to run `refresh_baseline.R`
- How to review `derivation_proposals.csv`
- Promotion workflow: curator edits `inst/extdata/ecotox/lifestage_derivation.csv`
- Repatch command: `.eco_patch_lifestage(refresh = "baseline")`

---

## Shared Patterns

### CSV Read (all R scripts)
**Source:** `R/eco_lifestage_patch.R` line 137 (`.eco_lifestage_read_csv`) + CONTEXT.md code_context
**Apply to:** `validate_36.R`, `refresh_baseline.R`, `test-eco_lifestage_data.R`

```r
# Preferred in test/dev script context (show_col_types = FALSE suppresses chatter)
readr::read_csv(path, show_col_types = FALSE)

# Used internally by .eco_lifestage_read_csv() — acceptable in dev scripts
utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
```

### CSV Write (all R scripts that modify CSVs)
**Source:** `R/eco_lifestage_patch.R` line 248 (`.eco_lifestage_cache_write`)
**Apply to:** `refresh_baseline.R`, any targeted CSV replacement script

```r
utils::write.csv(x, path, row.names = FALSE, na = "")
```

### CLI Messaging
**Source:** Throughout `dev/lifestage/*.R` and `R/eco_lifestage_patch.R`
**Apply to:** `validate_36.R`, `refresh_baseline.R`

```r
cli::cli_h1("Section title")          # top-level section header
cli::cli_h2("Subsection")             # subsection header
cli::cli_alert_success("Passed: ...")  # check passed
cli::cli_alert_info("Info: ...")       # informational
cli::cli_warn("Warning: ...")          # non-fatal issue (D-16)
cli::cli_abort("Error: ...")           # fatal; stops execution (D-07 mismatch)
```

### DB Connection + Cleanup
**Source:** `dev/lifestage/validate_lifestage.R` lines 18-19, `tests/testthat/test-eco_lifestage_gate.R` lines 296-297
**Apply to:** `validate_36.R` (completeness section), `refresh_baseline.R`

```r
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
```

### Path Resolution
**Source:** `R/eco_connection.R` lines 12-18, `R/eco_lifestage_patch.R` lines 92-129
**Apply to:** `validate_36.R`, `refresh_baseline.R`

```r
db_path        <- eco_path()                    # resolves ecotox.duckdb
baseline_path  <- .eco_lifestage_baseline_path()  # resolves inst/extdata/... with dev fallback
derivation_path <- .eco_lifestage_derivation_path()
```

### Anti-Join Cross-Check
**Source:** RESEARCH.md Pattern 1 + dplyr throughout v2.4 code
**Apply to:** `test-eco_lifestage_data.R`, `validate_36.R`

```r
# Always distinct() the left side first to avoid counting multi-org_lifestage keys as separate gaps
resolved_keys <- dplyr::distinct(resolved, source_ontology, source_term_id)
gaps <- dplyr::anti_join(resolved_keys, derivation, by = c("source_ontology", "source_term_id"))
```

### Dev Script Package Load
**Source:** `dev/lifestage/validate_35.R` line 6
**Apply to:** `validate_36.R`, `refresh_baseline.R`

```r
suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `dev/lifestage/README.md` | documentation | — | No existing README in `dev/lifestage/`; no dev-script documentation precedent in the repository |

---

## Key Pitfalls (from RESEARCH.md — critical for planner)

| Pitfall | Risk | Pattern to Apply |
|---------|------|-----------------|
| Pitfall 5: calling `.eco_lifestage_cache_schema()` in testthat | Test fails if package load fails | Hardcode expected column vectors in test file |
| Pitfall 6: anti-join returns 20 rows for 7 distinct keys | Wrong row count assertion | Use `dplyr::distinct(source_ontology, source_term_id)` before anti-join |
| Pitfall 4: partial CSV write with separate write calls | Inconsistent quoting | Load full baseline → replace rows in-memory → single `write.csv` call |
| Pitfall 3: targeting wrong rows for D-03 replacement | Wrong rows modified | Filter by `source_term_id == "GO:0040007"`, not by description |

---

## Metadata

**Analog search scope:** `dev/lifestage/`, `tests/testthat/`, `R/eco_lifestage_patch.R`, `R/eco_connection.R`, `inst/extdata/ecotox/`
**Files scanned:** 9
**Pattern extraction date:** 2026-04-23
