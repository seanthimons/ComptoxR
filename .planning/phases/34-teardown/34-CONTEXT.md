# Phase 34: Teardown - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Remove all v2.3 regex-first lifestage harmonization artifacts from the codebase and confirm the DB is in a clean state ready for the v2.4 source-backed pipeline. This is primarily a verification + cleanup phase — most removal work was already completed during v2.3→v2.4 transition.

</domain>

<decisions>
## Implementation Decisions

### Verification Scope
- **D-01:** Verify criteria 1 & 2 via automated grep checks (`.classify_lifestage_keywords()` absent from R/inst/data-raw, `ontology_id` absent from function signatures/roxygen/relocate calls). Both are already true in current source — verification confirms the state.
- **D-02:** Remove `LIFESTAGE_HARMONIZATION_PLAN.md` (root-level old v2.3 plan doc containing superseded classifier code). `LIFESTAGE_HARMONIZATION_PLAN2.md` (v2.4 plan) stays.

### DB Purge Method
- **D-03:** Write a dev/ script that: (1) drops `lifestage_dictionary` and `lifestage_review` from `ecotox.duckdb` if they exist, (2) calls `.eco_patch_lifestage(refresh = "baseline")`, (3) confirms both tables are recreated with correct schemas. Uses the real DB for maximum realism.

### Test File Disposition
- **D-04:** Leave `test-eco_lifestage_gate.R` as-is. These tests are v2.4-forward (testing patch paths, cache-hit, baseline-seeded, quarantine behavior for `eco_lifestage_patch.R`), not v2.3 artifacts. They'll be validated in later phases (35-39).

### Claude's Discretion
- Dev script location and naming within `dev/` directory
- Exact grep patterns used for verification checks
- Whether to add the verification grep output to the dev script or keep it separate

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Implementation Plan
- `LIFESTAGE_HARMONIZATION_PLAN2.md` — v2.4 source-backed resolution plan (the active plan)

### Key Source Files
- `R/eco_lifestage_patch.R` — Shared helper layer (926 lines, 14 functions) including `.eco_patch_lifestage()`
- `R/eco_functions.R` — Runtime enrichment (`.eco_enrich_metadata()` join against `lifestage_dictionary`)
- `inst/ecotox/ecotox_build.R` §section-16 — Build script lifestage materialization
- `data-raw/ecotox.R` §section-16 — Dev build script lifestage materialization

### Artifacts to Remove
- `LIFESTAGE_HARMONIZATION_PLAN.md` — Old v2.3 plan doc (to be deleted)

### Test Files (leave as-is)
- `tests/testthat/test-eco_lifestage_gate.R` — v2.4 patch pipeline tests
- `tests/testthat/test-eco_functions.R` — Contains `ontology_id` absence assertion (valid v2.4 test)

</canonical_refs>

<code_context>
## Existing Code Insights

### Current State (already completed)
- `.classify_lifestage_keywords()` — already absent from `R/`, `inst/`, `data-raw/`
- `ontology_id` — already absent from R source and build scripts; only in tests asserting its absence
- Build scripts (both copies) already call `eco_lifestage_patch.R` shared helpers in section 16
- `eco_functions.R` already joins against `lifestage_dictionary` table

### Reusable Assets
- `.eco_patch_lifestage(refresh = "baseline")` in `R/eco_lifestage_patch.R` — the function that rebuilds tables from committed CSV
- `.eco_lifestage_release_id()` — extracts release ID from zip path for metadata
- `.eco_lifestage_materialize_tables()` — creates dictionary + review tibbles

### Integration Points
- `ecotox.duckdb` — target database for table purge and recreation
- `inst/extdata/ecotox/lifestage_baseline.csv` — committed CSV for cold-start rebuild
- `inst/extdata/ecotox/lifestage_derivation.csv` — derivation mapping CSV

</code_context>

<specifics>
## Specific Ideas

No specific requirements — standard verification and cleanup approach.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 34-teardown*
*Context gathered: 2026-04-22*
