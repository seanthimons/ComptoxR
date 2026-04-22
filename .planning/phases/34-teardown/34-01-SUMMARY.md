---
phase: 34-teardown
plan: 01
subsystem: ecotox-lifestage
tags: [teardown, v2.3-removal, v2.4-migration, duckdb, lifestage]
dependency_graph:
  requires: []
  provides:
    - R/eco_lifestage_patch.R (v2.4 shared helper layer, 14 functions)
    - inst/extdata/ecotox/lifestage_baseline.csv (cold-start baseline)
    - inst/extdata/ecotox/lifestage_derivation.csv (derivation rules)
    - dev/lifestage/purge_and_rebuild.R (TEAR-03 dev script)
  affects:
    - inst/ecotox/ecotox_build.R (section 16 replaced)
    - data-raw/ecotox.R (section 16 replaced)
    - R/eco_functions.R (relocate() and @return updated)
    - ecotox.duckdb (lifestage_dictionary v2.4 schema, lifestage_review created)
tech_stack:
  added:
    - R/eco_lifestage_patch.R (926 lines, 14 internal functions)
    - inst/extdata/ecotox/lifestage_baseline.csv (139 rows committed baseline)
    - inst/extdata/ecotox/lifestage_derivation.csv (derivation rules CSV)
    - dev/lifestage/purge_and_rebuild.R (TEAR-03 dev script)
  patterns:
    - .eco_lifestage_materialize_tables() for build-time integration
    - .eco_patch_lifestage(refresh="baseline") for post-build patching
    - DuckDB read-only connection: shutdown=FALSE to avoid WAL revert
key_files:
  created:
    - R/eco_lifestage_patch.R
    - dev/lifestage/purge_and_rebuild.R
    - inst/extdata/ecotox/lifestage_baseline.csv
    - inst/extdata/ecotox/lifestage_derivation.csv
  modified:
    - inst/ecotox/ecotox_build.R
    - data-raw/ecotox.R
    - R/eco_functions.R
    - .gitignore
decisions:
  - shutdown=FALSE required for read-only assertion connections in DuckDB scripts to avoid WAL revert
  - .eco_lifestage_materialize_tables() used directly in build scripts (not .eco_patch_lifestage() which requires file-based DB)
  - test-eco_lifestage_gate.R left as-is per D-04 despite containing v2.3 ontology_id data definitions
metrics:
  duration: ~30 minutes
  completed: 2026-04-22T17:26:47Z
  tasks_completed: 2
  tasks_total: 2
  files_modified: 8
---

# Phase 34 Plan 01: Teardown v2.3 Lifestage Artifacts Summary

**One-liner:** Purged v2.3 regex-first lifestage classifier and ontology_id from build scripts and eco_functions.R; rebuilt ecotox.duckdb with 13-column v2.4 schema via .eco_patch_lifestage(refresh="baseline").

## What Was Built

### Task 1: Source Tree Cleanup + Purge Script Creation

**TEAR-01 (classify_lifestage_keywords removal):**
Section 16 of `inst/ecotox/ecotox_build.R` and `data-raw/ecotox.R` contained a v2.3 inline function `.classify_lifestage_keywords()` (~40 lines each) and a 5-column 139-row `life_stage` tribble with `ontology_id`. Both were replaced with a call to `.eco_lifestage_materialize_tables(refresh="baseline")` from the new `R/eco_lifestage_patch.R` shared helper layer.

**TEAR-02 (ontology_id removal):**
- `R/eco_functions.R`: Removed `ontology_id` from `dplyr::relocate()` column list and `@return` roxygen block; replaced `classification_source` with `derivation_source` to match v2.4 schema.
- Both build scripts: ontology_id was part of the tribble definition — removed with the full v2.3 section 16 replacement.

**D-02 (plan doc deletion):**
`LIFESTAGE_HARMONIZATION_PLAN.md` (19 KB, v2.3 plan) deleted from project root.
`LIFESTAGE_HARMONIZATION_PLAN2.md` (v2.4 plan) preserved.

**TEAR-03 (purge-and-rebuild script):**
Created `dev/lifestage/purge_and_rebuild.R` following the `confirm_gate.R` header pattern. Script: (1) drops v2.3 tables, (2) calls `.eco_patch_lifestage(refresh="baseline")`, (3) asserts v2.4 13-column schema with no `ontology_id`.

**Supporting files added to git:**
- `R/eco_lifestage_patch.R` — 926-line v2.4 shared helper layer (was untracked)
- `inst/extdata/ecotox/lifestage_baseline.csv` — committed 139-row baseline (was untracked)
- `inst/extdata/ecotox/lifestage_derivation.csv` — derivation rules (was untracked)
- `.gitignore` — added exceptions for the two lifestage CSVs

### Task 2: DB Rebuild + Schema Verification

Ran `purge_and_rebuild.R` against the live `ecotox.duckdb`. Result:
- `lifestage_dictionary`: 53 rows, 13-column v2.4 schema, no `ontology_id`
- `lifestage_review`: 86 rows quarantined (terms not fully resolved by baseline)
- Schema assertion: PASS ("v2.4 schema confirmed")
- `devtools::test(filter="eco_lifestage_gate")`: 6/6 PASS, 0 failures

## Verification Results

| Check | Result |
|-------|--------|
| TEAR-01: `grep "classify_lifestage_keywords" R/ inst/ data-raw/` | PASS (exit 1, zero matches) |
| TEAR-02: `grep "ontology_id" R/ inst/ data-raw/` | PASS (exit 1, zero matches) |
| TEAR-02 tests: `grep "ontology_id" tests/` | Expected — test-eco_lifestage_gate.R has v2.3 data (see Deviations) |
| D-02: LIFESTAGE_HARMONIZATION_PLAN.md deleted | PASS |
| D-02: LIFESTAGE_HARMONIZATION_PLAN2.md preserved | PASS |
| TEAR-03: purge_and_rebuild.R exits 0 | PASS |
| TEAR-03: "Schema assertion passed" in output | PASS |
| TEAR-03: "TEAR-03 complete" in output | PASS |
| TEAR-03: "Dictionary rows: 53" (>0) | PASS |
| Regression: eco_lifestage_gate 6/6 | PASS |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] RESEARCH.md stated v2.3 cleanup already done — was incorrect**
- **Found during:** Task 1 Step C (grep verification)
- **Issue:** RESEARCH.md claimed "no `.classify_lifestage_keywords()` definition or call exists in any of those directories" — but `inst/ecotox/ecotox_build.R` and `data-raw/ecotox.R` both contained the full v2.3 section 16 (~215 lines each). The research was written speculatively.
- **Fix:** Replaced section 16 in both files with `.eco_lifestage_materialize_tables()` call (TEAR-01 + TEAR-02 fix). Also added `R/eco_lifestage_patch.R`, `inst/extdata/ecotox/lifestage_baseline.csv`, and `inst/extdata/ecotox/lifestage_derivation.csv` which were untracked.
- **Files modified:** `inst/ecotox/ecotox_build.R`, `data-raw/ecotox.R`, `.gitignore`
- **Additional files added:** `R/eco_lifestage_patch.R`, `inst/extdata/ecotox/lifestage_baseline.csv`, `inst/extdata/ecotox/lifestage_derivation.csv`
- **Commit:** 1a987c5

**2. [Rule 1 - Bug] DuckDB WAL revert when read-only connection uses shutdown=TRUE**
- **Found during:** Task 2 Step C (fresh R session schema verification)
- **Issue:** `purge_and_rebuild.R` Step 3 opened a read-only `con2` with `on.exit(DBI::dbDisconnect(con2, shutdown = TRUE))`. This caused DuckDB to revert the write connection's WAL on Windows, making `lifestage_review` invisible to subsequent sessions. The schema assertion within the same script passed (con2 saw the freshly written state before the engine shutdown), but a new session found `lifestage_review` absent.
- **Fix:** Changed `shutdown = TRUE` to `shutdown = FALSE` on the read-only assertion connection `con2`. The write connection from `.eco_patch_lifestage()` already closes with `shutdown = TRUE` (line 848 of `eco_lifestage_patch.R`), so the checkpoint is correctly triggered there.
- **Files modified:** `dev/lifestage/purge_and_rebuild.R`
- **Commit:** 2978b51

### Plan Expectation Mismatch (not a code deviation)

**test-eco_lifestage_gate.R contains v2.3 ontology_id data definitions:**
- The plan must_haves stated "ontology_id references in tests/ are exclusively absence assertions (expect_false)".
- Actual state: `test-eco_lifestage_gate.R` (lines 40, 47) contains `ontology_id` in a v2.3 `life_stage` tribble and `.classify_lifestage_keywords()` inline definition — these are data definitions, not absence assertions.
- Per D-04 (locked decision): "Leave `test-eco_lifestage_gate.R` as-is. These are v2.4-forward tests."
- **Resolution:** Left as-is per D-04. TEAR-01 and TEAR-02 grep scopes are explicitly `R/ inst/ data-raw/` — `tests/` is not in scope for those checks.

## Known Stubs

None — all data flows through `R/eco_lifestage_patch.R` with committed baseline CSVs. The `lifestage_dictionary` has 53 resolved rows and `lifestage_review` has 86 quarantined rows (expected — these are terms not covered by the baseline OLS4/NVS resolution, addressed in Phase 35 live resolution).

## Threat Flags

None — this phase performs no network operations, handles no user input, and introduces no new authentication paths.

## Self-Check

**Checking created files exist:**
- dev/lifestage/purge_and_rebuild.R: FOUND (created in Task 1)
- R/eco_lifestage_patch.R: FOUND (copied from main project, committed)
- inst/extdata/ecotox/lifestage_baseline.csv: FOUND (committed)
- inst/extdata/ecotox/lifestage_derivation.csv: FOUND (committed)

**Checking commits exist:**
- 1a987c5 (feat(34-01): purge v2.3 lifestage artifacts): FOUND
- 2978b51 (fix(34-01): use shutdown=FALSE): FOUND

## Self-Check: PASSED
