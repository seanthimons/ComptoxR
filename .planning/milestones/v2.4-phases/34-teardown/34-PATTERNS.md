# Phase 34: Teardown - Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 2 (1 new, 1 deleted)
**Analogs found:** 2 / 2

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `dev/lifestage/purge_and_rebuild.R` (NEW) | dev utility | file-I/O + batch | `dev/lifestage/confirm_gate.R` | exact |
| `LIFESTAGE_HARMONIZATION_PLAN.md` (DELETE) | doc artifact | — | — | n/a — deletion only |

**Verification tasks (no new files):**
- TEAR-01 grep check — inline bash/R scan, no persistent file
- TEAR-02 grep check — inline bash/R scan, no persistent file

---

## Pattern Assignments

### `dev/lifestage/purge_and_rebuild.R` (dev utility, file-I/O + batch)

**Analog:** `dev/lifestage/confirm_gate.R`
**Secondary analog:** `dev/lifestage/validate_lifestage.R`

**Imports pattern** (`dev/lifestage/confirm_gate.R` lines 1-11):
```r
#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(dplyr)
  library(cli)
})

source("R/eco_connection.R")
source("R/eco_lifestage_patch.R")
```
All dev scripts in `dev/lifestage/` use this exact header. `dplyr` can be omitted if no
tibble manipulation is performed in the script body; `cli` is always required.

**DB path resolution + existence guard** (`dev/lifestage/confirm_gate.R` lines 13-16,
`dev/lifestage/validate_lifestage.R` lines 13-16):
```r
db_path <- eco_path()
if (!file.exists(db_path)) {
  cli::cli_abort("ECOTOX DuckDB not found at {.path {db_path}}.")
}
```
Use `eco_path()` — never hardcode the DB path. The variable name is `db_path` across all
existing analogs (not `source_db`, which `confirm_gate.R` uses only because it then copies
to a temp file — not applicable for purge_and_rebuild).

**Read-write connection with on.exit cleanup** (`dev/lifestage/confirm_gate.R` lines 22-25):
```r
.eco_close_con()

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = tmp_db, read_only = FALSE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
```
Critical: `.eco_close_con()` must be called BEFORE opening any read-write connection.
DuckDB on Windows enforces single-writer exclusivity — a cached read-only connection in
`.ComptoxREnv$ecotox_db` blocks the write open. The `on.exit(..., add = TRUE)` pattern
ensures disconnection even on error. Always pass `shutdown = TRUE` to `dbDisconnect`.

**Table existence check + drop pattern** (derived from `R/eco_connection.R` `.eco_close_con()`
lines 70-74 and DBI conventions used throughout the package):
```r
for (tbl in c("lifestage_dictionary", "lifestage_review")) {
  if (DBI::dbExistsTable(con, tbl)) {
    DBI::dbRemoveTable(con, tbl)
    cli::cli_alert_success("Dropped {.code {tbl}}")
  } else {
    cli::cli_alert_info("{.code {tbl}} not present — skipped")
  }
}
```
Use `DBI::dbRemoveTable()` not `DBI::dbExecute("DROP TABLE ...")`. Use
`DBI::dbExistsTable()` to guard the removal so the script is idempotent.

**Connection handoff before calling `.eco_patch_lifestage()`** (derived from
`R/eco_lifestage_patch.R` line 834 and connection lifecycle pattern in confirm_gate.R):
```r
DBI::dbDisconnect(con, shutdown = TRUE)
.eco_close_con()

# Now rebuild — .eco_patch_lifestage opens its own read-write connection internally
result <- .eco_patch_lifestage(db_path = db_path, refresh = "baseline")
```
The manual drop connection MUST be fully closed (with `shutdown = TRUE`) AND
`.eco_close_con()` called again before invoking `.eco_patch_lifestage()`. The patch
function calls `.eco_close_con()` at line 834 internally, but doing it explicitly in the
script first makes the lifecycle visible and prevents race conditions.

**Result reporting after `.eco_patch_lifestage()`** (`dev/lifestage/confirm_gate.R` lines 42-43):
```r
cli::cli_alert_success("Dictionary rows: {result$dictionary_rows}")
cli::cli_alert_info("Review rows: {result$review_rows}")
cli::cli_alert_info("Refresh mode: {result$refresh_mode}")
```
The return value of `.eco_patch_lifestage()` is a named list with keys `db_path`,
`ecotox_release`, `dictionary_rows`, `review_rows`, `refresh_mode`.

**Schema assertion pattern** (derived from `R/eco_lifestage_patch.R` lines 27-43 and
`tests/testthat/test-eco_functions.R` `live_schema_ready` column-name check):
```r
con2 <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con2, shutdown = TRUE), add = TRUE)

actual_cols  <- DBI::dbListFields(con2, "lifestage_dictionary")
expected_cols <- names(.eco_lifestage_dictionary_schema())

if ("ontology_id" %in% actual_cols) {
  cli::cli_abort("FAIL: ontology_id still present in lifestage_dictionary schema")
}
missing <- setdiff(expected_cols, actual_cols)
if (length(missing) > 0) {
  cli::cli_abort("FAIL: missing v2.4 columns: {paste(missing, collapse=', ')}")
}
if (!DBI::dbExistsTable(con2, "lifestage_review")) {
  cli::cli_abort("FAIL: lifestage_review table not created")
}

cli::cli_alert_success("Schema assertion passed — v2.4 schema confirmed")
cli::cli_alert_success("TEAR-03 complete")
```
Assert by column names (not count). The 13 v2.4 dictionary columns are defined in
`.eco_lifestage_dictionary_schema()` (`R/eco_lifestage_patch.R` lines 27-43).
Explicitly assert absence of `ontology_id` as the TEAR-02 signal.

**cli heading pattern** (`dev/lifestage/confirm_gate.R` line 33, `validate_lifestage.R` line 27):
```r
cli::cli_h1("TEAR-03: Purge v2.3 Lifestage Tables and Rebuild")
cli::cli_alert_info("Target DB: {.path {db_path}}")
```
Use `cli::cli_h1()` for the top-level script title; `cli::cli_h2()` for sub-steps.
Use `{.path ...}` for file paths, `{.code ...}` for table/column names.

---

### `LIFESTAGE_HARMONIZATION_PLAN.md` (deletion)

**No pattern required** — this is a plain `git rm` or `file.remove()` operation.
The file is at `C:/Users/sxthi/Documents/ComptoxR/LIFESTAGE_HARMONIZATION_PLAN.md`
(confirmed present on disk, 19 KB). `LIFESTAGE_HARMONIZATION_PLAN2.md` at the same
location MUST be preserved.

---

## Shared Patterns

### Connection Lifecycle (DuckDB read-write)
**Source:** `R/eco_connection.R` lines 70-77 (`.eco_close_con()`), `dev/lifestage/confirm_gate.R` lines 22-31
**Apply to:** `dev/lifestage/purge_and_rebuild.R` — every read-write open

```r
# Before any read-write open:
.eco_close_con()

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

# Before calling .eco_patch_lifestage():
DBI::dbDisconnect(con, shutdown = TRUE)
.eco_close_con()
```

### DB Path Resolution
**Source:** `R/eco_connection.R` lines 12-18 (`eco_path()`), used in all dev/lifestage scripts
**Apply to:** `dev/lifestage/purge_and_rebuild.R`

```r
db_path <- eco_path()
if (!file.exists(db_path)) {
  cli::cli_abort("ECOTOX DuckDB not found at {.path {db_path}}.")
}
```

### Grep Verification (TEAR-01 / TEAR-02 — inline task, no persistent file)
**Source:** `34-RESEARCH.md` Pattern 2 (derived from project grep conventions)
**Apply to:** Plan tasks for TEAR-01 and TEAR-02

```r
# TEAR-01: classify_lifestage_keywords absent from R/, inst/, data-raw/
dirs_to_check <- c("R", "inst", "data-raw")
pattern_1 <- "classify_lifestage_keywords"
hits_1 <- unlist(lapply(dirs_to_check, function(d) {
  if (!dir.exists(d)) return(character(0))
  files <- list.files(d, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  unlist(lapply(files, function(f) {
    lines <- readLines(f, warn = FALSE)
    idx <- grep(pattern_1, lines, fixed = TRUE)
    if (length(idx) > 0) paste0(f, ":", idx) else character(0)
  }))
}))

if (length(hits_1) > 0) {
  cli::cli_abort("TEAR-01 FAIL: {pattern_1} found:\n{paste(hits_1, collapse='\n')}")
} else {
  cli::cli_alert_success("TEAR-01 PASS: {pattern_1} absent from R/, inst/, data-raw/")
}
```

Scope grep to named directories only — never the repo root. `.claude/worktrees/`
directories contain stale v2.3 code that would produce false positives.

---

## No Analog Found

All files in scope have close analogs. No entries needed here.

---

## Metadata

**Analog search scope:** `dev/lifestage/`, `R/eco_connection.R`, `R/eco_lifestage_patch.R`
**Files scanned:** 4 analog files read in full
**Pattern extraction date:** 2026-04-22
