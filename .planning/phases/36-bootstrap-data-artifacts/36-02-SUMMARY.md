---
phase: 36-bootstrap-data-artifacts
plan: "02"
subsystem: testing
status: checkpoint
tags: [ecotox, lifestage, validation, dev-scripts, documentation]

requires:
  - phase: 36-bootstrap-data-artifacts
    plan: "01"
    provides: clean CSV artifacts (baseline 139 rows, derivation 53 rows) and CI cross-check gate

provides:
  - dev/lifestage/validate_36.R: one-shot Phase 36 data artifact integrity verification
  - dev/lifestage/refresh_baseline.R: future-release baseline refresh with proposal staging
  - dev/lifestage/README.md: curator documentation for the full refresh workflow

affects:
  - 36-bootstrap-data-artifacts (Task 3 checkpoint — curator sign-off pending)
  - 37-rebuild-path (can proceed once curator approves PO mappings)

tech-stack:
  added: []
  patterns:
    - "Dev script pattern: devtools::load_all + cli::cli_h1/h2 sections + stopifnot gates"
    - "DB-optional completeness check: file.exists guard + cli_warn skip path"
    - "Derivation proposal staging: write to derivation_proposals.csv, never to committed derivation CSV"

key-files:
  created:
    - dev/lifestage/validate_36.R
    - dev/lifestage/refresh_baseline.R
    - dev/lifestage/README.md

key-decisions:
  - "validate_36.R follows validate_35.R structural pattern exactly: 4 sections with cli_h2 headers and stopifnot gates"
  - "DB-optional completeness check: file.exists guard emits cli_warn + graceful skip when no DB present (D-07)"
  - "refresh_baseline.R writes proposals to derivation_proposals.csv only — never to committed lifestage_derivation.csv (D-02/D-14)"
  - "D-16: refresh script emits cli_warn (not cli_abort) for derivation gaps to give curator control of pacing"

duration: 15min
completed: 2026-04-23
---

# Phase 36 Plan 02: Dev Scripts and Curator Documentation Summary

**Phase 36 verification script and future-release refresh workflow created with full curator documentation; awaiting checkpoint sign-off on PO:0000055/PO:0009010 provisional mappings before plan marked complete.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-23
- **Completed:** 2026-04-23 (checkpoint pending)
- **Tasks:** 2 auto (complete) + 1 checkpoint (pending)
- **Files created:** 3

## Accomplishments

- Created `dev/lifestage/validate_36.R` with 4 validation sections: schema checks (13-col baseline, 5-col derivation), cross-check gate (anti-join resolved keys vs derivation), GO:0040007 contamination check, and DB-optional completeness check with release match gate. Script runs successfully — all checks pass.
- Created `dev/lifestage/refresh_baseline.R` with 3-step workflow: fetch DB terms, re-resolve all terms via OLS4+NVS, check derivation coverage and stage proposals. Never writes to committed derivation CSV (D-02 compliant).
- Created `dev/lifestage/README.md` documenting the complete refresh workflow: when to run, prerequisites, 5-step procedure, and curator rules (no auto-commit to derivation, CI gate reference).

## Task Commits

1. **Task 1: validate_36.R and refresh_baseline.R** - `4c60efa` (feat)
2. **Task 2: dev/lifestage/README.md curator documentation** - `41eb958` (docs)

## Files Created

- `dev/lifestage/validate_36.R` — 4-section verification script; runs successfully with all-green output including DB completeness check (release: ecotox_ascii_03_12_2026.zip, 139 terms confirmed)
- `dev/lifestage/refresh_baseline.R` — Future-release refresh script; writes to baseline CSV and stages proposals in derivation_proposals.csv
- `dev/lifestage/README.md` — Curator workflow documentation covering prerequisites, 5-step refresh procedure, and important rules

## Checkpoint: Awaiting Curator Sign-Off

**Task 3 (checkpoint:human-verify) blocked pending:**

1. Run validation script and confirm all-green output
2. Run testthat gate and confirm 0 failures
3. Curator review of two provisional PO mappings from Plan 01:
   - `PO:0000055` (bud/inflorescence) → Adult, reproductive_stage=TRUE
   - `PO:0009010` (seed) → Egg/Embryo, reproductive_stage=FALSE

## Decisions Made

- validate_36.R uses `readr::read_csv(path, show_col_types = FALSE)` per established project pattern
- DB-optional section uses `file.exists(db_path)` guard with `cli::cli_warn` for absent DB (D-07)
- Release mismatch triggers `cli::cli_abort` with informative message (D-07)
- refresh_baseline.R proposals get `derivation_source = "curator_review"` marker

## Deviations from Plan

None - plan executed exactly as written. Both scripts match the structural patterns specified in the plan and PATTERNS.md.

## Known Stubs

None. All scripts reference real package functions and produce actual output.

## Self-Check: PASSED

- `dev/lifestage/validate_36.R`: exists, contains `cli::cli_h1`, `stopifnot(ncol(baseline) == 13L)`, `stopifnot(ncol(derivation) == 5L)`, `dplyr::anti_join`, `eco_path()`, `cli::cli_warn` for DB-absent, `cli::cli_abort` for release mismatch, `GO:0040007`, outputs "Phase 36 Validation Complete" and "All checks passed"
- `dev/lifestage/refresh_baseline.R`: exists, contains `.eco_lifestage_resolve_term`, `derivation_proposals.csv`, `cli::cli_warn` for derivation gaps, does NOT write to `lifestage_derivation.csv`
- `dev/lifestage/README.md`: exists, contains `refresh_baseline.R`, `derivation_proposals.csv`, `eco_patch_lifestage`, `Prerequisites`, `test-eco_lifestage_data`
- Commits exist: 4c60efa (feat), 41eb958 (docs)
- validate_36.R runs successfully: all 4 sections pass, "All checks passed" confirmed

---
*Phase: 36-bootstrap-data-artifacts*
*Status: checkpoint — awaiting curator sign-off on PO:0000055 and PO:0009010 mappings*
