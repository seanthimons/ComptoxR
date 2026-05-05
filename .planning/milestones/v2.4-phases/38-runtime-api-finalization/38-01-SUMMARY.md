---
phase: 38-runtime-api-finalization
plan: "01"
subsystem: api
tags: [ecotox, lifestage, duckdb, plumber, testthat, roxygen]

requires:
  - phase: 37-build-patch-integration
    provides: patched ECOTOX lifestage_dictionary and lifestage_codes runtime tables
provides:
  - compact default eco_results() lifestage output
  - detailed lifestage_details output mode with source_match_method
  - stale lifestage runtime schema guard
  - shared DuckDB and Plumber lifestage output selector
affects: [eco_results, ecotox, lifestage, plumber]

tech-stack:
  added: []
  patterns:
    - shared internal output selector for local and Plumber routes
    - local DuckDB schema guard before lifestage metadata joins

key-files:
  created:
    - .planning/phases/38-runtime-api-finalization/38-01-SUMMARY.md
  modified:
    - R/eco_functions.R
    - tests/testthat/test-eco_lifestage_gate.R
    - tests/testthat/test-eco_functions.R
    - man/eco_results.Rd

key-decisions:
  - "Default eco_results() output is compact: org_lifestage, harmonized_life_stage, reproductive_stage."
  - "Detailed source-backed provenance is exposed only through lifestage_details = TRUE."
  - "ontology_id is removed from every runtime output mode."
  - "Runtime enrichment validates and joins lifestage_codes and lifestage_dictionary only."

patterns-established:
  - "Use .eco_select_lifestage_output() to keep DuckDB and Plumber output visibility aligned."
  - "Use .eco_validate_lifestage_runtime_schema() before lifestage joins so stale DBs abort with patch/rebuild guidance."

requirements-completed: [RUNT-01, RUNT-02, RUNT-03, D-01, D-02, D-03, D-04, D-05, D-06, D-07, D-08, D-09, D-10, D-11, D-12, D-13, D-14, D-15, D-16, D-17, D-18, D-19, D-20, D-21, D-22, D-23]

duration: 52min
completed: 2026-04-28
---

# Phase 38: Runtime API Finalization Summary

**Compact default and detailed source-backed lifestage modes for eco_results() across DuckDB and Plumber routes**

## Performance

- **Duration:** 52 min
- **Started:** 2026-04-28T12:55:00-04:00
- **Completed:** 2026-04-28T13:47:10-04:00
- **Tasks:** 4
- **Files modified:** 4

## Accomplishments

- Added `lifestage_details = FALSE` to `eco_results()` and propagated it through `.eco_results_plumber()`.
- Added `.eco_select_lifestage_output()` so compact default and detailed output ordering are shared across local and Plumber-backed results.
- Added `.eco_validate_lifestage_runtime_schema()` so missing or stale lifestage tables/columns abort with patch/rebuild guidance.
- Updated targeted tests for compact output, detailed output, `source_match_method`, `ontology_id` absence, stale schema handling, and runtime exclusion of `lifestage_review`.
- Regenerated `man/eco_results.Rd` from roxygen.

## Task Commits

1. **Tasks 1-4: Runtime API tests, implementation, Plumber parity, docs, and verification** - `a7e44f6` (feat)

Note: the plan was executed inline because Phase 38 had one plan and no parallel wave split. The final implementation was committed as a single scoped commit after targeted verification, with pre-existing unrelated workspace changes left unstaged.

## Files Created/Modified

- `R/eco_functions.R` - Adds `lifestage_details`, shared output selection, Plumber normalization, `source_match_method`, and stale schema guard.
- `tests/testthat/test-eco_lifestage_gate.R` - Adds local temporary DuckDB contract tests for compact/default and detailed lifestage behavior.
- `tests/testthat/test-eco_functions.R` - Updates live DB expectations to match the compact default and detailed mode.
- `man/eco_results.Rd` - Documents the new argument and both output modes.
- `.planning/phases/38-runtime-api-finalization/38-01-SUMMARY.md` - Records execution outcome.

## Decisions Made

- Preserved the Phase 38 context refinement: RUNT-01's detailed source-backed contract is tested through `lifestage_details = TRUE`, not the default output.
- Kept the selector focused on output visibility and ordering; join behavior remains in `.eco_enrich_metadata()`.
- Used an explicit temporary DuckDB connection in the new test fixture to avoid existing cached-connection behavior affecting the runtime API contract test.

## Deviations from Plan

None - plan scope was followed. The only execution adjustment was using a single scoped implementation commit instead of per-task commits because the working tree already contained unrelated pre-existing changes.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion; changes stayed inside runtime output, tests, and generated documentation.

## Issues Encountered

- `gsd-sdk query` is not available in this shell, so execute-phase state updates were handled by direct file/workflow execution where possible.
- The initial red test run showed the intended failures: default provenance exposure, missing `lifestage_details`, and stale schema returning without the planned guard.
- During implementation, the schema guard initially treated empty missing-column sets as prefixed missing values; this was fixed before final verification.

## Verification

- `Rscript -e "devtools::test(filter='eco_lifestage_gate')"` - PASS, 49 passing assertions.
- `Rscript -e "devtools::document()"` - PASS, regenerated `man/eco_results.Rd`.
- `Rscript -e "devtools::test(filter='eco_(functions|lifestage_gate)')"` - PASS, 82 passing assertions.
- `git diff -- R/eco_functions.R tests/testthat/test-eco_lifestage_gate.R tests/testthat/test-eco_functions.R man/eco_results.Rd` - PASS, diff limited to runtime output contract, tests, and generated docs.

Full package check was not run; Phase 38 acceptance intentionally uses targeted testthat coverage.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 38's user-facing runtime lifestage contract is implemented and covered by targeted tests. Phase 39 can treat `eco_results()` compact/default and detailed output modes as stable.

## Self-Check: PASSED

- Default output exposes only `org_lifestage`, `harmonized_life_stage`, and `reproductive_stage` from the lifestage block.
- Detailed output exposes the Phase 38 source-backed block including `source_match_method`.
- `ontology_id` is absent in both modes.
- `.eco_enrich_metadata()` joins `lifestage_codes` and `lifestage_dictionary`; the source-level test verifies it does not reference `lifestage_review`.
- Stale local lifestage schema aborts with patch/rebuild guidance.

---
*Phase: 38-runtime-api-finalization*
*Completed: 2026-04-28*
