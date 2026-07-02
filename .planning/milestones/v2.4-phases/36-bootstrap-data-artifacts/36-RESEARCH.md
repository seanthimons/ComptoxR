# Phase 36: Bootstrap Data Artifacts - Research

**Researched:** 2026-04-23
**Domain:** R package data artifacts — CSV integrity, testthat gates, dev scripts
**Confidence:** HIGH

## Summary

Phase 36 is a data-integrity and test-authoring phase, not a code-authoring phase. The two committed CSV files already exist on disk and have correct schemas. The work is: (1) close 7 cross-check gaps by hand-authoring derivation rows and re-resolving 3 contaminated baseline rows, (2) write a permanent `testthat` gate that CI enforces forever, (3) write a `validate_36.R` dev script, and (4) write a `refresh_baseline.R` + `README.md` for future maintainers.

The completeness check confirms the baseline already covers all 139 distinct `lifestage_codes.description` values from `ecotox_ascii_03_12_2026.zip`. No baseline rows need to be added — only 3 rows need their `source_ontology`/`source_term_id` corrected (the GO:0040007 contamination), and 6 derivation rows need to be hand-authored (plus a 7th conditional on D-03 re-resolution outcome).

**Primary recommendation:** Execute in three ordered tasks — (A) fix data, (B) write testthat gate, (C) write dev scripts — because the gate tests the final data state and the dev script invokes the gate.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Hand-author derivation rows for the 6 legitimate missing keys: `S11:S1116` (adult), `S11:S1122` (egg), `S11:S1106` (embryo), `S11:S1128` (larva), `PO:0000055` (bud/inflorescence), `PO:0009010` (seed). Add 7th row if re-resolution of the `GO:0040007` terms (D-03) produces a mappable ID.
- **D-02:** No regex backstop. `lifestage_derivation.csv` is curator-authored only.
- **D-03:** Re-resolve the 3 contaminated rows ("Exponential growth phase (log)", "Lag growth phase", "Stationary growth phase") via the Phase-35 prefix-filtered `.eco_lifestage_resolve_term()`. Replace those 3 rows in `lifestage_baseline.csv`.
- **D-04:** Expected outcome of D-03 is `unresolved` — UBERON/PO/S11 do not cover microbial growth phases.
- **D-05:** Targeted dev-script replacement — do not regenerate the full 139-row baseline.
- **D-06:** Criterion 1 verification = live anti-join between `DISTINCT description` from `lifestage_codes` (via `.eco_connection()`) and `org_lifestage` in `lifestage_baseline.csv`.
- **D-07:** Release match gate — script reads `ecotox_release` from baseline and compares against DB. Mismatch → `cli_abort`; DB absent → `cli_warn` and graceful skip.
- **D-08:** No committed snapshot artifact. DB is source of truth for completeness.
- **D-09:** Permanent gate = `testthat` test at `tests/testthat/test-eco_lifestage_data.R`. Pure CSV read + anti-join. No network or DB dependency. CI-safe.
- **D-10:** Test assertions: (1) every baseline resolved row has a derivation partner; (2) derivation has exactly 5 expected columns; (3) baseline has exactly 13 columns from `.eco_lifestage_cache_schema()`.
- **D-11:** Phase 36 verification script = `dev/lifestage/validate_36.R`.
- **D-12:** No auto-rebuild inside `.eco_patch_lifestage()`.
- **D-13:** Refresh script writes updated `inst/extdata/ecotox/lifestage_baseline.csv` directly.
- **D-14:** Auto-suggested derivation rows written to `dev/lifestage/derivation_proposals.csv` — never directly into `lifestage_derivation.csv`.
- **D-15:** Refresh procedure documented in `dev/lifestage/README.md`.
- **D-16:** Refresh script emits `cli_warn` (not `cli_abort`) on derivation gaps.

### Claude's Discretion

- Exact structure/naming inside `dev/lifestage/` directory
- Testthat file organization (single file vs split assertions)
- CLI output formatting for verification and refresh scripts
- Whether to include the 3 re-resolved rows' unresolved status in validate_36.R report as a visible diff

### Deferred Ideas (OUT OF SCOPE)

- Phase 37: `cli_alert_info` on rebuild paths surfacing quarantined `needs_derivation` rows
- Future v2.5+: GO (Gene Ontology) provider support for microbial growth-phase terms
- Future: `ECOX-01` automated ontology version tracking
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | `lifestage_baseline.csv` committed to `inst/extdata/ecotox/` covering current ECOTOX release | Verified: 139 rows, 13 cols, `ecotox_ascii_03_12_2026.zip`. Completeness confirmed (0 terms missing from DB). 3 rows need GO:0040007 re-resolution. |
| DATA-02 | `lifestage_derivation.csv` mapping `source_ontology + source_term_id` to `harmonized_life_stage` and `reproductive_stage` | Verified: 47 rows, 5 cols. 6 keys (7 rows of baseline resolved) missing derivation partners — hand-authoring required. |
| DATA-03 | Cross-check gate — every resolved baseline row must have a matching derivation row before commit | Verified gap: 7 distinct `(source_ontology, source_term_id)` keys unmatched. Permanent gate → `tests/testthat/test-eco_lifestage_data.R`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Data artifact integrity | Package data layer (`inst/extdata/`) | testthat CI gate | CSV files are shipped with the installed package; integrity is a pre-commit concern |
| Cross-check verification | testthat (CI-enforced) | dev script (human-readable) | Pure file read — no network/DB needed, runs in any CI environment |
| Completeness check | Dev script only | DB (`ecotox.duckdb`) | Requires live DB; not CI-safe; one-shot human verification per release |
| Future refresh | Curator dev script | `inst/extdata/` | Manual workflow; proposals staged for review before promotion |

## Standard Stack

### Core (all already in package Imports)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| readr | existing | CSV read in refresh script | Already in Imports; `show_col_types = FALSE` pattern established |
| dplyr | existing | Anti-join for cross-check, data manipulation | Used throughout v2.4 code |
| cli | existing | User-facing messages in dev scripts | Package-wide convention |
| testthat | existing | CI gate | Package test framework |
| DBI + duckdb | existing | DB connection for completeness check | Already in Imports |

No new dependencies needed. [VERIFIED: STATE.md — "No new DESCRIPTION dependencies needed"]

### Supporting Patterns Already Established

| Pattern | Location | Notes |
|---------|----------|-------|
| `readr::read_csv(..., show_col_types = FALSE)` | CONTEXT.md code_context | Preferred for CSV reads in R code |
| `utils::read.csv(...)` | `eco_lifestage_patch.R:137` | Used by `.eco_lifestage_read_csv()` — acceptable in dev scripts |
| `utils::write.csv(x, path, row.names = FALSE, na = "")` | `eco_lifestage_patch.R:248` | Canonical CSV write |
| `cli::cli_abort` / `cli::cli_warn` / `cli::cli_alert_info` | Throughout v2.4 | All user messages |
| `dplyr::anti_join()` | Standard dplyr | Cross-check mechanism |
| `suppressPackageStartupMessages(devtools::load_all(...))` | `validate_35.R:6` | Dev script header pattern |

## Architecture Patterns

### System Architecture Diagram

```
Data Fix (D-03, D-01)
    |
    v
inst/extdata/ecotox/lifestage_baseline.csv  <--[3 rows replaced: GO:0040007 -> unresolved]
inst/extdata/ecotox/lifestage_derivation.csv <--[6 new rows hand-authored]
    |
    v
tests/testthat/test-eco_lifestage_data.R  (CI gate, pure CSV read)
    |---- assert: baseline has 13 cols
    |---- assert: derivation has 5 cols
    |---- assert: anti_join(resolved_baseline, derivation) == 0 rows
    |
dev/lifestage/validate_36.R  (human-readable, DB-optional)
    |---- re-runs D-10 assertions with verbose output
    |---- completeness anti-join (baseline vs DB lifestage_codes)
    |---- release match check (D-07)
    |
dev/lifestage/refresh_baseline.R  (future-release refresh)
    |---- calls .eco_lifestage_resolve_term() for all DB terms
    |---- writes inst/extdata/ecotox/lifestage_baseline.csv
    |---- writes dev/lifestage/derivation_proposals.csv (new keys only)
    |---- cli_warn on gaps (D-16)
    |
dev/lifestage/README.md  (curator documentation)
```

### Recommended Project Structure (additions only)

```
dev/lifestage/
├── validate_35.R        # existing
├── validate_36.R        # NEW — one-shot phase verification
├── refresh_baseline.R   # NEW — future-release refresh workflow
├── README.md            # NEW — curator documentation
└── derivation_proposals.csv  # generated by refresh script (gitignored or committed?)
tests/testthat/
├── test-eco_lifestage_gate.R    # existing — leave as-is
└── test-eco_lifestage_data.R    # NEW — permanent cross-check gate
```

### Pattern 1: Cross-Check Anti-Join (D-10, DATA-03)

The cross-check in the testthat gate follows the same dplyr pattern used throughout the codebase. Pure CSV read, no package load required.

```r
# Source: established dplyr anti_join pattern; schema from .eco_lifestage_cache_schema()
test_that("every resolved baseline row has a derivation partner", {
  baseline_path <- system.file(
    "extdata", "ecotox", "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  derivation_path <- system.file(
    "extdata", "ecotox", "lifestage_derivation.csv",
    package = "ComptoxR"
  )
  baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
  derivation <- readr::read_csv(derivation_path, show_col_types = FALSE)

  resolved <- dplyr::filter(baseline, source_match_status == "resolved")
  gaps <- dplyr::anti_join(
    resolved,
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

### Pattern 2: Schema Column Count Assertions (D-10)

```r
# Source: .eco_lifestage_cache_schema() line 8, .eco_lifestage_dictionary_schema() line 27
test_that("baseline CSV has 13 expected columns", {
  path <- system.file("extdata", "ecotox", "lifestage_baseline.csv", package = "ComptoxR")
  df <- readr::read_csv(path, show_col_types = FALSE)
  expected_cols <- names(.eco_lifestage_cache_schema())
  expect_equal(sort(names(df)), sort(expected_cols))
})

test_that("derivation CSV has 5 expected columns", {
  path <- system.file("extdata", "ecotox", "lifestage_derivation.csv", package = "ComptoxR")
  df <- readr::read_csv(path, show_col_types = FALSE)
  expected_cols <- c("source_ontology", "source_term_id",
                     "harmonized_life_stage", "reproductive_stage", "derivation_source")
  expect_equal(sort(names(df)), sort(expected_cols))
})
```

### Pattern 3: Dev Script Structure (from validate_35.R)

```r
#!/usr/bin/env Rscript
# Phase 36: Bootstrap Data Artifacts Validation
# Run from project root: Rscript dev/lifestage/validate_36.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

cli::cli_h1("Phase 36 Validation")
# ... sections with cli_h2, cli_alert_success, stopifnot
cli::cli_h1("Phase 36 Validation Complete")
cli::cli_alert_success("All checks passed.")
```

### Anti-Patterns to Avoid

- **Regenerating all 139 baseline rows:** D-05 explicitly forbids full regeneration. Only 3 rows (GO:0040007 contamination) need replacement via targeted script.
- **Direct write to `lifestage_derivation.csv` from automation:** D-02/D-14 forbid this. Proposals go to `derivation_proposals.csv` for curator review.
- **Network calls in testthat:** The cross-check gate must be pure CSV read. No OLS4, NVS, or DB calls.
- **Using `cli_abort` for derivation gaps in refresh script:** D-16 mandates `cli_warn` — the curator controls the pacing of commits.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Term re-resolution | Custom OLS4/NVS call | `.eco_lifestage_resolve_term()` | Already handles prefix filter + NVS resilience from Phase 35 |
| CSV read with schema validation | Custom parser | `.eco_lifestage_read_csv()` + `.eco_lifestage_validate_cache()` | Handles NA strings, type coercion |
| Derivation map read | Custom CSV read | `.eco_lifestage_derivation_map()` | Already reads, validates, deduplicates |
| DB path resolution | Custom path logic | `eco_path()` from `R/eco_connection.R` | Handles option + R_user_dir fallback |
| Release ID from DB | Custom query | `.eco_lifestage_release_id(con)` | Already handles _metadata table read |

## Current Data State (VERIFIED)

All figures verified by running R analysis against actual files on 2026-04-23.

### Baseline CSV (`inst/extdata/ecotox/lifestage_baseline.csv`)

| Metric | Value | Source |
|--------|-------|--------|
| Total rows | 139 | [VERIFIED: file read] |
| Resolved rows | 73 | [VERIFIED: file read] |
| Unresolved rows | 66 | [VERIFIED: file read] |
| Distinct resolved `(source_ontology, source_term_id)` keys | 54 | [VERIFIED: file read] |
| `ecotox_release` value | `ecotox_ascii_03_12_2026.zip` | [VERIFIED: file read] |
| Column count | 13 | [VERIFIED: matches `.eco_lifestage_cache_schema()`] |
| DB completeness | 0 terms in DB missing from baseline | [VERIFIED: anti-join vs DB] |
| DB completeness | 0 terms in baseline missing from DB | [VERIFIED: anti-join vs DB] |

### Derivation CSV (`inst/extdata/ecotox/lifestage_derivation.csv`)

| Metric | Value | Source |
|--------|-------|--------|
| Total rows | 47 | [VERIFIED: file read] |
| Column count | 5 | [VERIFIED: file read] |

### Cross-Check Gaps (7 distinct keys, 20 affected baseline rows)

| source_ontology | source_term_id | source_term_label | Action Required | Provisional Mapping |
|-----------------|----------------|-------------------|-----------------|--------------------|
| S11 | S1116 | adult | Hand-author derivation row (D-01) | Adult, reproductive_stage=FALSE |
| S11 | S1122 | egg | Hand-author derivation row (D-01) | Egg/Embryo, reproductive_stage=FALSE |
| S11 | S1106 | embryo | Hand-author derivation row (D-01) | Egg/Embryo, reproductive_stage=FALSE |
| S11 | S1128 | larva | Hand-author derivation row (D-01) | Larva, reproductive_stage=FALSE |
| PO | PO:0000055 | bud | Hand-author derivation row (D-01) | Adult, reproductive_stage=TRUE (curator sign-off needed) |
| PO | PO:0009010 | seed | Hand-author derivation row (D-01) | Egg/Embryo, reproductive_stage=FALSE (curator sign-off needed) |
| UBERON | GO:0040007 | growth | Re-resolve via D-03; expected → unresolved | N/A (microbial term) |

[VERIFIED: file read + cross-join analysis, 2026-04-23]

### Cross-Ontology Contamination Detail

The UBERON-ontology rows have 7 non-`UBERON:`-prefixed IDs. Of these 7, **4 already have derivation entries** (CL:0000019, CL:0000023, CL:0010017, GO:0007565) and are not gaps. Only **GO:0040007** (3 baseline rows: "Exponential growth phase (log)", "Lag growth phase", "Stationary growth phase") has no derivation partner AND needs re-resolution per D-03.

[VERIFIED: merge analysis against derivation CSV]

## Common Pitfalls

### Pitfall 1: Conflating "contamination" with "gap"

**What goes wrong:** All 7 non-`UBERON:`-prefixed IDs in UBERON rows are treated as gaps. Only GO:0040007 is actually a gap. CL:0000019, CL:0000023, CL:0010017, and GO:0007565 have existing derivation entries and are correctly mapped.
**How to avoid:** Run the anti-join to identify actual missing keys, not just the prefix filter.

### Pitfall 2: system.file() returns "" in dev load_all() context

**What goes wrong:** `system.file(..., package = "ComptoxR")` returns `""` when running tests via `devtools::test()` before the package is installed.
**How to avoid:** The existing `.eco_lifestage_baseline_path()` already handles this — it falls back to `file.path("inst", "extdata", "ecotox", "lifestage_baseline.csv")`. In the testthat gate, use `system.file()` (which works post-`devtools::load_all()`) or call the helper. The test-gate file should use `system.file()` since `devtools::load_all()` installs to a temp lib. Verify by running `devtools::test(filter="eco_lifestage_data")` once the file is created.

### Pitfall 3: D-03 re-resolution targeting — "Subadult" row

**What goes wrong:** The baseline has a "Subadult" row that is currently `unresolved` (not a GO:0040007 row). The 3 rows to re-resolve are specifically: "Exponential growth phase (log)", "Lag growth phase", "Stationary growth phase" — all sharing `source_term_id = GO:0040007`.
**How to avoid:** Filter by `source_term_id == "GO:0040007"` in the targeted script, not by "Subadult" or other terms.

### Pitfall 4: write.csv encoding for baseline replacement

**What goes wrong:** Using `write.csv` for the 3-row replacement produces inconsistent quoting with the existing 136 rows if done via separate writes and manual merge.
**How to avoid:** Load full baseline, replace 3 rows in-memory, write the whole file back with `utils::write.csv(x, path, row.names = FALSE, na = "")` — consistent with `.eco_lifestage_cache_write()` at line 248 of `eco_lifestage_patch.R`.

### Pitfall 5: testthat gate calling internal functions directly

**What goes wrong:** The gate calls `.eco_lifestage_cache_schema()` to get expected column names, which requires the package to be loaded. If the package fails to load, the test fails for the wrong reason.
**How to avoid:** Hardcode the expected column vectors in the test file rather than calling the schema function. This makes the test self-contained and explicit about what it checks.

### Pitfall 6: PO:0000055 appears 3 times, PO:0009010 appears twice

**What goes wrong:** Multiple `org_lifestage` values map to the same `(source_ontology, source_term_id)` key. The derivation gap cross-check detects the key as missing, but only one derivation row per key is needed.
**How to avoid:** When computing gaps, use `dplyr::distinct(source_ontology, source_term_id)` on the resolved baseline before the anti-join, or understand that the anti-join returns 20 rows (multiple `org_lifestage` values sharing 7 distinct keys) but only 6 new derivation rows are required (7th conditional on D-03).

## Code Examples

### Targeted 3-row baseline replacement (D-03, D-05)

```r
# Source: established pattern from eco_lifestage_patch.R:248
# Run from project root

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

baseline_path <- .eco_lifestage_baseline_path()
baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)

# Re-resolve the 3 GO:0040007 contaminated rows
go_terms <- baseline[
  !is.na(baseline$source_term_id) & baseline$source_term_id == "GO:0040007",
]
ecotox_release <- unique(stats::na.omit(baseline$ecotox_release))

re_resolved <- purrr::map_dfr(
  go_terms$org_lifestage,
  .eco_lifestage_resolve_term,
  ecotox_release = ecotox_release
)

# Replace rows in-place
baseline_updated <- dplyr::rows_update(
  baseline,
  re_resolved,
  by = "org_lifestage",
  unmatched = "ignore"
)

utils::write.csv(baseline_updated, baseline_path, row.names = FALSE, na = "")
cli::cli_alert_success("Replaced {nrow(re_resolved)} rows in baseline.")
```

### Completeness anti-join for validate_36.R (D-06)

```r
# Source: established pattern from validate_lifestage.R
db_path <- eco_path()
if (!file.exists(db_path)) {
  cli::cli_warn("ECOTOX DB not found — completeness check skipped.")
} else {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  db_release <- .eco_lifestage_release_id(con)
  baseline_release <- unique(stats::na.omit(baseline$ecotox_release))
  if (!identical(db_release, baseline_release)) {
    cli::cli_abort("Release mismatch: DB={db_release}, baseline={baseline_release}")
  }

  db_terms <- DBI::dbGetQuery(
    con, "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
  )$description

  missing <- setdiff(db_terms, baseline$org_lifestage)
  if (length(missing) == 0) {
    cli::cli_alert_success("Completeness: all {length(db_terms)} DB terms present in baseline.")
  } else {
    cli::cli_abort("Baseline missing {length(missing)} DB term(s): {missing}")
  }
}
```

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.x (existing) |
| Config file | `tests/testthat.R` (existing) |
| Quick run command | `devtools::test(filter="eco_lifestage_data")` |
| Full suite command | `devtools::test()` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | baseline has 13 expected columns | unit | `devtools::test(filter="eco_lifestage_data")` | No — Wave 0 |
| DATA-01 | baseline covers all ECOTOX lifestage terms (completeness) | manual-only | `Rscript dev/lifestage/validate_36.R` | No — Wave 0 |
| DATA-02 | derivation has exactly 5 expected columns | unit | `devtools::test(filter="eco_lifestage_data")` | No — Wave 0 |
| DATA-03 | anti-join of resolved baseline vs derivation returns 0 rows | unit | `devtools::test(filter="eco_lifestage_data")` | No — Wave 0 |

### Sampling Rate

- Per task commit: `devtools::test(filter="eco_lifestage_data")`
- Per wave merge: `devtools::test()`
- Phase gate: Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `tests/testthat/test-eco_lifestage_data.R` — covers DATA-01 (schema), DATA-02, DATA-03

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `ecotox.duckdb` | D-06 completeness check, D-07 release check | Yes | `ecotox_ascii_03_12_2026.zip` | `cli_warn` + graceful skip (D-07) |
| OLS4 API | D-03 re-resolution of GO:0040007 terms | Assumed network-available | current | If unreachable, manually set `unresolved` in CSV |
| NVS SPARQL | D-03 re-resolution | Assumed network-available | current | NVS resilience from Phase 35 handles failures |
| air | R code formatting | Yes | 0.9.0 | — |
| jarl | R code linting | Yes | 0.5.0 | — |

[VERIFIED: DB path `C:\Users\sxthi\AppData\Roaming/R/data/R/ComptoxR/ecotox.duckdb`, 416 MB, release `ecotox_ascii_03_12_2026.zip`]

## Security Domain

No applicable ASVS categories. Phase is data-file editing and test authoring with no auth, network exposure, user input, or cryptographic operations.

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| regex-based lifestage classification (v2.3) | source-backed OLS4/NVS resolution (v2.4) | Provenance is real ontology IDs, not keyword matches |
| No cross-check gate | testthat anti-join gate (DATA-03) | Cross-check enforced at every `devtools::test()` run |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | D-03 re-resolution will return `unresolved` for GO:0040007 terms (D-04 expected outcome) | Current Data State | If OLS4 matches, a new derivation row is needed before the gate passes |
| A2 | `system.file()` works correctly in `devtools::test()` context for `inst/extdata/` files | Code Examples | Gate tests fail for wrong reason; use path helper fallback |
| A3 | OLS4 network is available when developer runs D-03 targeted script | Environment Availability | Must manually set 3 rows to `unresolved` in CSV |

## Open Questions (RESOLVED)

1. **`derivation_proposals.csv` — committed or gitignored?**
   - What we know: D-14 says it's written by the refresh script to `dev/lifestage/`. D-02 says it should never auto-commit.
   - What's unclear: Whether it should be gitignored (generated artifact) or committed (so proposals are version-controlled for curator review).
   - Recommendation: Gitignore it. The refresh script regenerates it on demand. Committing would create merge conflicts during concurrent refresh runs.
   - **RESOLVED:** Gitignore. D-14 specifies proposals are never auto-committed; the refresh script regenerates on demand.

2. **PO:0000055 and PO:0009010 curator sign-off**
   - What we know: CONTEXT.md flags these as judgment calls. Provisional mapping given (bud → Adult/reproductive=TRUE; seed → Egg/Embryo).
   - What's unclear: Whether the curator (user) has already approved the provisional mapping or needs an explicit review step in the plan.
   - Recommendation: Flag these two keys as "requires curator sign-off" in the PLAN.md task. Implementer should write the rows with the provisional mapping but annotate as needing confirmation before the task is marked complete.
   - **RESOLVED:** Provisional mappings written in Plan 01; curator sign-off via Plan 02 checkpoint:human-verify task.

## Sources

### Primary (HIGH confidence)

- `inst/extdata/ecotox/lifestage_baseline.csv` — read and analyzed directly; all row counts, column counts, gap analysis verified
- `inst/extdata/ecotox/lifestage_derivation.csv` — read and analyzed directly
- `R/eco_lifestage_patch.R` — read for schema functions, path helpers, established patterns
- `dev/lifestage/validate_35.R` — read for dev script structural pattern
- `ecotox.duckdb` (_metadata table) — confirmed release `ecotox_ascii_03_12_2026.zip`, 139 distinct lifestage terms
- `.planning/phases/36-bootstrap-data-artifacts/36-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence)

- `LIFESTAGE_HARMONIZATION_PLAN2.md` — background architecture context
- `tests/testthat/test-eco_lifestage_gate.R` — test pattern reference (20 tests, all passing)

## Metadata

**Confidence breakdown:**

- Current data state: HIGH — verified by direct file read and R analysis
- Required actions: HIGH — locked decisions fully specify what to do
- Code patterns: HIGH — all patterns exist in current codebase
- D-03 re-resolution outcome: MEDIUM — expected `unresolved` per D-04, but network-dependent

**Research date:** 2026-04-23
**Valid until:** 2026-05-23 (stable — data artifacts and test patterns are not fast-moving)
