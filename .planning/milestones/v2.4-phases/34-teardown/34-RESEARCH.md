# Phase 34: Teardown - Research

**Researched:** 2026-04-22
**Domain:** R package cleanup, DuckDB schema migration, grep-based verification
**Confidence:** HIGH

## Summary

Phase 34 is a verification-and-cleanup phase. The v2.3 regex-first lifestage implementation
has already been stripped from the active working tree (`R/`, `inst/`, `data-raw/`, `tests/`).
No `.classify_lifestage_keywords()` definition or call exists in any of those directories.
No `ontology_id` column reference exists in any function signature, roxygen block, or
relocate/rename call in source. Both success criteria for TEAR-01 and TEAR-02 are already
satisfied at the source level — the phase work is to confirm this via automated checks and
record the result.

TEAR-03 is the only substantive work: the live `ecotox.duckdb` at
`C:\Users\sxthi\AppData\Roaming\R\data\R\ComptoxR\ecotox.duckdb` contains a v2.3-schema
`lifestage_dictionary` table (columns: `org_lifestage`, `harmonized_life_stage`,
`ontology_id`, `reproductive_stage`, `classification_source`; 139 rows) with no
corresponding `lifestage_review` table. This table must be dropped and rebuilt via
`.eco_patch_lifestage(refresh = "baseline")` to produce the v2.4 schema.

The one file deletion required is `LIFESTAGE_HARMONIZATION_PLAN.md` at the repository root
(19 KB, last modified 2026-04-20), which documents the superseded v2.3 classifier design.
`LIFESTAGE_HARMONIZATION_PLAN2.md` (the active v2.4 plan) must be preserved.

**Primary recommendation:** Write a single `dev/lifestage/purge_and_rebuild.R` script that
drops the v2.3 `lifestage_dictionary`, calls `.eco_patch_lifestage(refresh = "baseline")`,
and asserts the resulting schema matches the v2.4 dictionary schema — then run it, delete
`LIFESTAGE_HARMONIZATION_PLAN.md`, and run the grep verification checks.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Verify TEAR-01 and TEAR-02 via automated grep checks. Both are already true in
  current source — verification confirms the state.
- **D-02:** Remove `LIFESTAGE_HARMONIZATION_PLAN.md` (root-level old v2.3 plan doc). Keep
  `LIFESTAGE_HARMONIZATION_PLAN2.md`.
- **D-03:** Write a `dev/` script that: (1) drops `lifestage_dictionary` and
  `lifestage_review` from `ecotox.duckdb` if they exist, (2) calls
  `.eco_patch_lifestage(refresh = "baseline")`, (3) confirms both tables are recreated with
  correct schemas. Uses the real DB for maximum realism.
- **D-04:** Leave `test-eco_lifestage_gate.R` as-is. These are v2.4-forward tests, not
  v2.3 artifacts.

### Claude's Discretion
- Dev script location and naming within `dev/` directory
- Exact grep patterns used for verification checks
- Whether to add the verification grep output to the dev script or keep it separate

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEAR-01 | Remove `.classify_lifestage_keywords()` regex classifier and all references | Confirmed absent from R/, inst/, data-raw/, tests/ — grep verification task only |
| TEAR-02 | Remove `ontology_id` column from all code paths, docs, and tests | Confirmed absent from source; only present in tests asserting its *absence* (valid) — grep verification task only |
| TEAR-03 | Purge `lifestage_dictionary` and `lifestage_review` tables from existing `ecotox.duckdb`; rebuild on-demand via patch | DB confirmed to have v2.3 schema dictionary; `.eco_patch_lifestage(refresh="baseline")` is the rebuild path |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Grep verification of source artifacts | Dev tooling | — | Read-only scan of working tree, no package code involved |
| File deletion (LIFESTAGE_HARMONIZATION_PLAN.md) | Dev tooling | — | Root-level doc removal, not a package artifact |
| DB purge + rebuild | DuckDB / Storage | R package (eco_lifestage_patch.R) | Live database mutation via `.eco_patch_lifestage()` |
| Schema assertion | Dev tooling | — | Post-rebuild check of resulting table columns |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| DBI | (already in DESCRIPTION) | DB connection and table operations | Package dependency |
| duckdb | (already in DESCRIPTION) | DuckDB driver for R | Package dependency |
| dplyr | (already in DESCRIPTION) | Data manipulation | Package dependency |
| cli | (already in DESCRIPTION) | User-facing messages | Package convention |

No new dependencies are required. All packages are already in DESCRIPTION Imports.
[VERIFIED: CLAUDE.md — "No new DESCRIPTION dependencies needed — all packages already in Imports"]

### Dev Script Pattern
Existing dev scripts in `dev/` use this header pattern (verified from `dev/lifestage/confirm_gate.R`):

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

Scripts reference `eco_path()` for the canonical DB location and call internal helpers directly.

---

## Architecture Patterns

### System Architecture Diagram

```
[grep scan] --> R/, inst/, data-raw/ --> [no matches] --> TEAR-01 PASS
                                      --> match found  --> FAIL (block)

[grep scan] --> R/, inst/, data-raw/, tests/ (fn sigs only)
            --> [no matches in sigs/roxygen/relocate] --> TEAR-02 PASS
            --> [matches only in absence assertions]   --> expected, PASS

[dev/lifestage/purge_and_rebuild.R]
     |
     v
eco_path() --> ecotox.duckdb
     |
     +--> DROP TABLE lifestage_dictionary (if exists)
     +--> DROP TABLE lifestage_review (if exists)
     |
     v
.eco_patch_lifestage(db_path, refresh = "baseline")
     |
     +--> reads _metadata (ecotox_release)
     +--> reads lifestage_codes.description (distinct)
     +--> .eco_lifestage_materialize_tables(refresh="baseline")
          |
          +--> reads inst/extdata/ecotox/lifestage_baseline.csv
          +--> reads inst/extdata/ecotox/lifestage_derivation.csv
          +--> returns list(dictionary, review, cache, refresh_mode)
     |
     +--> DBI::dbWriteTable("lifestage_dictionary", overwrite=TRUE)
     +--> DBI::dbWriteTable("lifestage_review", overwrite=TRUE)
     +--> updates _metadata (patch timestamp, method, version)
     |
     v
Schema assertion:
  - lifestage_dictionary cols == v2.4 schema (13 cols, no ontology_id)
  - lifestage_review exists (0+ rows ok)
  - TEAR-03 PASS
```

### Recommended Project Structure

No new directories needed. Script goes in existing `dev/lifestage/`:

```
dev/
└── lifestage/
    ├── confirm_gate.R       (existing — v2.4 smoke test)
    ├── validate_lifestage.R (existing — v2.4 validation)
    └── purge_and_rebuild.R  (NEW — TEAR-03 script)
```

### Pattern 1: Drop and Rebuild Tables via .eco_patch_lifestage

The `.eco_patch_lifestage()` function (line 888-889 of `R/eco_lifestage_patch.R`) uses
`DBI::dbWriteTable(..., overwrite = TRUE)`, which **replaces** an existing table including
its schema. No explicit `DROP TABLE` via SQL is strictly required — `overwrite = TRUE` handles
schema replacement atomically.

However, the D-03 decision asks the dev script to explicitly drop first (step 1), then call
the patch (step 2). This provides a clean demonstration that the purge path works from zero.
Pattern:

```r
# Source: R/eco_connection.R + R/eco_lifestage_patch.R (verified in codebase)

db_path <- eco_path()

.eco_close_con()  # release any cached read connection first

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)
on.exit({
  if (DBI::dbIsValid(con)) DBI::dbDisconnect(con, shutdown = TRUE)
  .eco_close_con()
}, add = TRUE)

if (DBI::dbExistsTable(con, "lifestage_dictionary")) {
  DBI::dbRemoveTable(con, "lifestage_dictionary")
  cli::cli_alert_info("Dropped lifestage_dictionary")
}
if (DBI::dbExistsTable(con, "lifestage_review")) {
  DBI::dbRemoveTable(con, "lifestage_review")
  cli::cli_alert_info("Dropped lifestage_review")
}

DBI::dbDisconnect(con, shutdown = TRUE)
.eco_close_con()

# Now rebuild
result <- .eco_patch_lifestage(db_path = db_path, refresh = "baseline")
```

**Critical:** `.eco_patch_lifestage()` opens its own read-write connection internally and
calls `.eco_close_con()` before doing so (line 834). The manual connection opened for the
drop step **must be closed before calling `.eco_patch_lifestage()`**, otherwise DuckDB will
throw a write-lock error. [VERIFIED: lines 834-851 of R/eco_lifestage_patch.R]

### Pattern 2: Grep Verification for TEAR-01 and TEAR-02

Grep patterns that confirm absence (exit code 1 = no match = pass):

**TEAR-01** — classify_lifestage_keywords absent from R/, inst/, data-raw/:
```bash
grep -rn "classify_lifestage_keywords" R/ inst/ data-raw/
# Expected: no output, exit code 1
```

**TEAR-02** — ontology_id absent from function signatures, roxygen @return, column
rename/relocate in R/, inst/, data-raw/:
```bash
# Broad scan first (should be empty):
grep -rn "ontology_id" R/ inst/ data-raw/
# Expected: no output, exit code 1

# In tests, presence only in expect_false() assertions is OK:
grep -rn "ontology_id" tests/
# Expected: lines 69 of test-eco_functions.R and 547 of test-eco_lifestage_gate.R only
#           (both are expect_false("ontology_id" %in% names(result)) — valid v2.4 tests)
```

These can be encoded in R using `system2()` or in a bash wrapper, per Claude's Discretion
(D-01 allows either approach).

### Pattern 3: Schema Assertion after Rebuild

After calling `.eco_patch_lifestage()`, verify the resulting schema matches the v2.4
dictionary schema defined in `.eco_lifestage_dictionary_schema()`:

```r
# Source: R/eco_lifestage_patch.R lines 27-43 (verified)
# v2.4 dictionary schema columns (13 columns):
# org_lifestage, source_ontology, source_term_id, source_term_label,
# source_term_definition, source_provider, source_match_method, source_match_status,
# source_release, ecotox_release, harmonized_life_stage, reproductive_stage,
# derivation_source

con2 <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con2, shutdown = TRUE), add = TRUE)

actual_cols <- DBI::dbListFields(con2, "lifestage_dictionary")
expected_cols <- names(ComptoxR:::.eco_lifestage_dictionary_schema())
# or equivalently: names(.eco_lifestage_dictionary_schema()) if sourced locally

stopifnot("ontology_id" %notin% actual_cols)
stopifnot(all(expected_cols %in% actual_cols))
stopifnot(DBI::dbExistsTable(con2, "lifestage_review"))
```

### Anti-Patterns to Avoid

- **Opening a read-write connection while another connection is cached:** DuckDB on Windows
  allows only one writer. Always call `.eco_close_con()` before opening a read-write
  connection, or before calling `.eco_patch_lifestage()` which opens its own.
  [VERIFIED: R/eco_lifestage_patch.R line 834]

- **Using `DBI::dbExecute("DROP TABLE ...")` instead of `DBI::dbRemoveTable()`:** Both work
  in DuckDB, but `dbRemoveTable` is the DBI-idiomatic approach and handles the
  "table does not exist" case more cleanly when combined with `dbExistsTable`.

- **Running `.eco_patch_lifestage(refresh = "live")` for TEAR-03:** The `baseline` mode is
  correct — it reads from the committed CSV without requiring live OLS4/NVS API access.
  `live` mode would call external ontology APIs that are not yet implemented (Phase 35).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Table drop/create | Manual SQL DDL | `DBI::dbRemoveTable()` + `DBI::dbWriteTable(..., overwrite=TRUE)` | Already in package; handles edge cases |
| Connection lifecycle | Manual open/close | `.eco_get_con()` / `.eco_close_con()` | Session cache invalidation, shutdown=TRUE for DuckDB |
| Lifestage table rebuild | Custom materialization | `.eco_patch_lifestage(refresh="baseline")` | 926-line shared helper; all edge cases handled |
| Schema validation | Manual column check | `.eco_lifestage_dictionary_schema()` as reference | Canonical schema definition in package |

---

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | `ecotox.duckdb` at `C:\Users\sxthi\AppData\Roaming\R\data\R\ComptoxR\ecotox.duckdb`: `lifestage_dictionary` (v2.3 schema, 139 rows, has `ontology_id`); `lifestage_review` absent | Drop `lifestage_dictionary`, call `.eco_patch_lifestage(refresh="baseline")` to recreate both tables with v2.4 schema |
| Live service config | None — no external services hold lifestage config | None |
| OS-registered state | None — no scheduled tasks or service registrations reference lifestage tables | None |
| Secrets/env vars | None — `ontology_id` does not appear in any env var names | None |
| Build artifacts | Pre-backup DB copy exists: `ecotox.pre-v2.3-20260421-155547.duckdb` at same dir — this is a safety backup, not an artifact to remove | None required; leave in place |

**Nothing found in category:** Live service config, OS-registered state, secrets/env vars —
verified by targeted inspection.

---

## Common Pitfalls

### Pitfall 1: DuckDB Write Lock on Windows
**What goes wrong:** Calling `.eco_patch_lifestage()` while a cached read-only connection
is still open causes DuckDB to throw "Can't open the database in read-write mode because an
existing read-only connection is open."
**Why it happens:** DuckDB on Windows enforces single-writer exclusivity; a cached read-only
connection in `.ComptoxREnv$ecotox_db` blocks the write open.
**How to avoid:** Always call `.eco_close_con()` before any read-write operation. The
`.eco_patch_lifestage()` function does this internally (line 834), but if the dev script
opens its own connection for the manual drop step, that connection must be explicitly
disconnected with `shutdown = TRUE` before `.eco_patch_lifestage()` is called.
**Warning signs:** `DBI::dbConnect()` throws an error containing "read-write" or "lock".

### Pitfall 2: Grep Matches in .claude/worktrees/
**What goes wrong:** Running grep without path restriction picks up `classify_lifestage_keywords`
hits in `.claude/worktrees/agent-*/` — stale worktree directories that are git-excluded.
**Why it happens:** The worktrees contain old implementations from previous agent runs during
v2.3 development.
**How to avoid:** Scope grep explicitly to `R/`, `inst/`, `data-raw/`, `dev/`, `tests/` rather
than the repo root. Do not run `grep -rn ... .` from the project root.
**Warning signs:** Matches showing paths containing `.claude/worktrees/`.

### Pitfall 3: Verifying Schema via Column Count Rather Than Column Names
**What goes wrong:** Asserting `length(cols) == 13` passes even if the wrong 13 columns are
present (e.g., old schema happened to have 13 columns too).
**Why it happens:** v2.3 had 5 columns; v2.4 has 13. A count check is insufficient; a name
check is required.
**How to avoid:** Assert specific column names, and specifically assert `"ontology_id" %notin%
actual_cols` as a direct TEAR-02 signal. [VERIFIED: test-eco_functions.R line 39-46 shows
the `live_schema_ready` check uses column name membership, not count]

### Pitfall 4: LIFESTAGE_HARMONIZATION_PLAN.md Contains Embedded R Code
**What goes wrong:** The file contains `.classify_lifestage_keywords` function code (lines 90-130
of the plan doc, confirmed by grep). If any tooling scans markdown for function definitions, it
might flag these as code that needs removal.
**Why it happens:** The plan doc was authored as documentation of the v2.3 implementation.
**How to avoid:** The fix is simply deleting the file via `file.remove()` or `git rm`. No
partial editing required.

---

## Code Examples

### Full dev script skeleton (purge_and_rebuild.R)

```r
#!/usr/bin/env Rscript
# TEAR-03: Purge v2.3 lifestage tables and rebuild via .eco_patch_lifestage(baseline)
# Run from: project root directory

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(cli)
})

source("R/eco_connection.R")
source("R/eco_lifestage_patch.R")

db_path <- eco_path()

if (!file.exists(db_path)) {
  cli::cli_abort("ECOTOX database not found at {.path {db_path}}.")
}

cli::cli_h1("TEAR-03: Purge v2.3 Lifestage Tables and Rebuild")
cli::cli_alert_info("Target DB: {.path {db_path}}")

# Step 1: Drop v2.3 tables
.eco_close_con()
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)

for (tbl in c("lifestage_dictionary", "lifestage_review")) {
  if (DBI::dbExistsTable(con, tbl)) {
    DBI::dbRemoveTable(con, tbl)
    cli::cli_alert_success("Dropped {.code {tbl}}")
  } else {
    cli::cli_alert_info("{.code {tbl}} not present — skipped")
  }
}

DBI::dbDisconnect(con, shutdown = TRUE)
.eco_close_con()

# Step 2: Rebuild via baseline
cli::cli_h2("Rebuilding via .eco_patch_lifestage(refresh = 'baseline')")
result <- .eco_patch_lifestage(db_path = db_path, refresh = "baseline")
cli::cli_alert_success("Dictionary rows: {result$dictionary_rows}")
cli::cli_alert_info("Review rows: {result$review_rows}")
cli::cli_alert_info("Refresh mode: {result$refresh_mode}")

# Step 3: Schema assertion
con2 <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con2, shutdown = TRUE), add = TRUE)

actual_cols <- DBI::dbListFields(con2, "lifestage_dictionary")
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

### Grep verification snippet (embeddable in a separate verify script or inline)

```r
# TEAR-01: classify_lifestage_keywords must be absent from R/, inst/, data-raw/
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
  cli::cli_abort("TEAR-01 FAIL: {pattern_1} found in:\n{paste(hits_1, collapse='\n')}")
} else {
  cli::cli_alert_success("TEAR-01 PASS: {pattern_1} absent from R/, inst/, data-raw/")
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `lifestage_dictionary` v2.3 schema: 5 cols (org_lifestage, harmonized_life_stage, ontology_id, reproductive_stage, classification_source) | v2.4 schema: 13 cols (source_ontology, source_term_id, source_term_label, source_term_definition, source_provider, source_match_method, source_match_status, source_release, ecotox_release, harmonized_life_stage, reproductive_stage, derivation_source) | v2.3 → v2.4 transition (Phase 33 → 34) | Schema mismatch causes `eco_results()` to fail `live_schema_ready` check |
| `.classify_lifestage_keywords()` regex classifier in build scripts | Removed; `eco_lifestage_patch.R` shared helper layer | Phase 33 | No more regex-only classification |

**Deprecated/outdated:**
- `ontology_id` column: present in current DB `lifestage_dictionary` (v2.3 artifact); absent from all source code; will be purged by TEAR-03.
- `classification_source` column: same as above (v2.3 only).
- `LIFESTAGE_HARMONIZATION_PLAN.md`: documents v2.3 design decisions; superseded by LIFESTAGE_HARMONIZATION_PLAN2.md.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `dev/lifestage/` is the correct location for `purge_and_rebuild.R` | Standard Stack | Low — Claude's Discretion allows alternative location within `dev/` |
| A2 | Pre-backup `ecotox.pre-v2.3-20260421-155547.duckdb` should be left in place | Runtime State Inventory | Low — it's a safety backup, not a v2.3 artifact |

---

## Open Questions

1. **Should the purge_and_rebuild.R script also emit grep verification output, or keep it separate?**
   - What we know: D-01 confirms grep verification; Claude's Discretion on whether to combine
   - What's unclear: Whether the planner wants one combined script or two focused scripts
   - Recommendation: Keep separate — `purge_and_rebuild.R` for TEAR-03, inline grep calls for
     TEAR-01/TEAR-02 as a verification task in the plan (not a persistent script)

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| R 4.5.1 | All R scripts | ✓ | 4.5.1 | — |
| DBI (R package) | DB operations | ✓ | in DESCRIPTION | — |
| duckdb (R package) | DB driver | ✓ | in DESCRIPTION | — |
| ecotox.duckdb | TEAR-03 rebuild | ✓ | present at `tools::R_user_dir("ComptoxR","data")` | — |
| inst/extdata/ecotox/lifestage_baseline.csv | `.eco_patch_lifestage(refresh="baseline")` | ✓ | present | — |
| inst/extdata/ecotox/lifestage_derivation.csv | `.eco_patch_lifestage(refresh="baseline")` | ✓ | present | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.x |
| Config file | `tests/testthat.R` (standard devtools layout) |
| Quick run command | `devtools::test(filter = "eco_lifestage_gate")` |
| Full suite command | `devtools::test()` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEAR-01 | `.classify_lifestage_keywords()` absent from R/, inst/, data-raw/ | verification (non-test) | grep check in plan task | N/A — grep task |
| TEAR-02 | `ontology_id` absent from fn sigs/roxygen/relocate | verification (non-test) | grep check in plan task | N/A — grep task |
| TEAR-03 | `lifestage_dictionary` + `lifestage_review` recreated with v2.4 schema after purge-and-rebuild | smoke test via dev script | `Rscript dev/lifestage/purge_and_rebuild.R` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** N/A (this phase has no ongoing test loop — it's run-and-verify)
- **Per wave merge:** `devtools::test(filter = "eco_lifestage_gate")` — confirms v2.4 tests still pass after DB rebuild
- **Phase gate:** All three requirement checks pass + `devtools::test()` green

### Wave 0 Gaps
- [ ] `dev/lifestage/purge_and_rebuild.R` — covers TEAR-03 (to be created in Wave 1)

*(TEAR-01 and TEAR-02 verification is in-plan grep tasks, not persistent test files)*

---

## Security Domain

This phase performs no network operations, handles no user input, and introduces no
authentication paths. ASVS categories V2, V3, V4, V6 do not apply. V5 (Input Validation)
is not relevant — the only inputs are DB file paths resolved from `eco_path()`, which is
a package-internal resolver. No security domain review required for this phase.

---

## Sources

### Primary (HIGH confidence)
- `R/eco_lifestage_patch.R` (lines 825-925) — `.eco_patch_lifestage()` implementation; verified connection lifecycle and overwrite behavior
- `R/eco_connection.R` (lines 12-77) — `eco_path()` and `.eco_close_con()` — verified DB path resolution
- `tests/testthat/test-eco_functions.R` (lines 35-46) — `live_schema_ready` guard — confirms v2.4 schema column expectations
- Live DB inspection — confirmed v2.3 schema in `ecotox.duckdb` at `C:\Users\sxthi\AppData\Roaming\R\data\R\ComptoxR\`

### Secondary (MEDIUM confidence)
- `dev/lifestage/confirm_gate.R` — reference pattern for dev script structure and connection lifecycle
- `data-raw/ecotox.R` section 16 — confirmed v2.4 build script does not contain `.classify_lifestage_keywords()`

### Tertiary (LOW confidence)
None.

---

## Metadata

**Confidence breakdown:**
- Current source state (TEAR-01/02): HIGH — direct grep verification
- DB state (TEAR-03): HIGH — direct DB inspection
- Dev script pattern: HIGH — modeled on existing `dev/lifestage/` scripts
- Connection lifecycle: HIGH — verified from source

**Research date:** 2026-04-22
**Valid until:** 2026-05-22 (stable — no external dependencies)
