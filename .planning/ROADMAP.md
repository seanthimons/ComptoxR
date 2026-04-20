# Roadmap: ComptoxR Stub Generation Pipeline

## Milestones

- v1.0 Stub Generation Fix — Phases 1-2 (shipped 2026-01-27)
- v1.1 Raw Text Body Fix — Phase 3 (shipped 2026-01-27)
- v1.2 Bulk Request Body Type Fix — Phase 4 (shipped 2026-01-28)
- v1.3 Chemi Resolver Integration Fix — Phase 5 (shipped 2026-01-28)
- v1.4 Empty POST Endpoint Detection — Phase 6 (shipped 2026-01-29)
- v1.5 Swagger 2.0 Body Schema Support — Phases 7-9 (shipped 2026-01-29)
- v1.6 Unified Stub Generation Pipeline — Phase 10 (shipped 2026-01-30)
- v1.7 Documentation Refresh — Phase 11 (shipped 2026-01-29)
- v1.8 Testing Infrastructure — Phases 12-15 (shipped 2026-01-31)
- v1.9 Schema Check Workflow Fix — Phases 16-18 (shipped 2026-02-12)
- v2.0 Paginated Requests — Phases 19-21 (shipped 2026-02-24)
- v2.1 Test Infrastructure — Phases 23-26 (shipped 2026-03-02, verified 2026-03-09)
- v2.2 Package Stabilization — Phases 27-30 (shipped 2026-03-11)
- **v2.3 ECOTOX Lifestage Harmonization** — Phases 31-33 (active)

## Phases

<details>
<summary>v1.0-v1.9 (Phases 1-18) — SHIPPED</summary>

- [x] Phase 1: Fix Body Parameter Extraction (2/2 plans) — completed 2026-01-27
- [x] Phase 2: Validate and Regenerate (2/2 plans) — completed 2026-01-27
- [x] Phase 3: Raw Text Body (2/2 plans) — completed 2026-01-27
- [x] Phase 4: JSON Body Default (3/3 plans) — completed 2026-01-28
- [x] Phase 5: Resolver Integration Fix (1/1 plan) — completed 2026-01-28
- [x] Phase 6: Empty POST Detection (1/1 plan) — completed 2026-01-29
- [x] Phase 7: Version Detection (2/2 plans) — completed 2026-01-29
- [x] Phase 8: Reference Resolution (2/2 plans) — completed 2026-01-29
- [x] Phase 9: Integration Validation (1/1 plan) — completed 2026-01-29
- [x] Phase 10: Pipeline Consolidation (1/1 plan) — completed 2026-01-30
- [x] Phase 11: Documentation Update (1/1 plan) — completed 2026-01-29
- [x] Phase 12: Test Infrastructure Setup (1/1 plan) — completed 2026-01-30
- [x] Phase 13: Unit Tests (2/2 plans) — completed 2026-01-31
- [x] Phase 14: Integration CI (2/2 plans) — completed 2026-01-31
- [x] Phase 15: Integration Test Fixes (1/1 plan) — completed 2026-01-31
- [x] Phase 16: CI Fix (1/1 plan) — completed 2026-02-12
- [x] Phase 17: Schema Diffing (2/2 plans) — completed 2026-02-12
- [x] Phase 18: Reliability (1/1 plan) — completed 2026-02-12

</details>

<details>
<summary>v2.0 Paginated Requests (Phases 19-21) — SHIPPED 2026-02-24</summary>

- [x] Phase 19: Pagination Detection (1/1 plan) — completed 2026-02-24
- [x] Phase 20: Auto-Pagination Engine (2/2 plans) — completed 2026-02-24
- [x] Phase 21: Stub Generation Integration (1/1 plan) — completed 2026-02-24

</details>

<details>
<summary>v2.1 Test Infrastructure (Phases 23-26) — SHIPPED 2026-03-02 (verified 2026-03-09)</summary>

> **Verification note (2026-03-09):** 3 plans had missing summaries due to a documentation
> gap (work was executed but summaries were not written). Retroactive summaries created
> after investigation confirmed all work was completed. Stale 07-version-detection-body-extraction
> directory deleted.

- [x] Phase 23: Build Fixes & Test Generator Core (5/5 plans) — completed 2026-02-27
- [x] Phase 24: VCR Cassette Cleanup (3/3 plans) — completed 2026-02-27
- [x] Phase 25: Automated Test Generation Pipeline (3/3 plans) — completed 2026-03-01
- [x] Phase 26: Pagination Tests & Coverage Hardening (2/2 plans) — completed 2026-03-01

</details>

<details>
<summary>v2.2 Package Stabilization (Phases 27-30) — SHIPPED 2026-03-11</summary>

- [x] Phase 27: Test Infrastructure Stabilization (3/3 plans) — completed 2026-03-10
- [x] Phase 28: Thin Wrapper Migration (5/5 plans) — completed 2026-03-11
- [x] Phase 29: Direct Template Migration (2/2 plans) — completed 2026-03-11
- [x] Phase 30: Build Quality Validation (1/1 plan) — completed 2026-03-11

</details>

### v2.3 ECOTOX Lifestage Harmonization (Phases 31-33) — ACTIVE

**Milestone Goal:** Replace the static 2-column lifestage dictionary with an ontology-backed 5-column schema featuring a two-axis design (developmental stage + reproductive flag), keyword regex fallback classifier, and a hard blocking build gate.

- [x] **Phase 31: Standalone Validation** (2 plans) - Define classifier + dictionary, validate against live ECOTOX DB read-only, prove all assertions pass (completed 2026-04-20)
- [x] **Phase 32: Build Pipeline Integration** (2 plans) - Integrate validated code into ecotox_build.R and eco_functions.R (completed 2026-04-20)
- [x] **Phase 33: Build Confirmation** (2 plans) - Run full ECOTOX build with gate active, verify outputs, pass devtools::check() (completed 2026-04-20)

## Phase Details

### Phase 31: Standalone Validation
**Goal**: Dictionary schema, keyword classifier, and data corrections are proven correct in complete isolation before touching any production code
**Depends on**: Nothing (first phase of v2.3; reads existing ECOTOX DuckDB read-only)
**Requirements**: DICT-01, DICT-02, DICT-03, DICT-04, KWCL-01, KWCL-02, KWCL-03, CORR-01, CORR-02, CORR-03, VALD-01, VALD-02
**Success Criteria** (what must be TRUE):
  1. A self-contained validation script defines the complete 5-column lifestage dictionary tribble (144+ rows) with columns `org_lifestage`, `harmonized_life_stage`, `ontology_id`, `reproductive_stage`, `classification_source`
  2. `.classify_lifestage_keywords()` function classifies arbitrary character input via priority-ordered regex and achieves at least 130/144 non-Other/Unknown matches on known descriptions
  3. Reproductive flag fires independently of developmental stage (e.g., "Reproductive adult" gets Adult + reproductive_stage=TRUE)
  4. All 10 two-axis deterministic assertions pass (6 misclassification fixes verified, Larva/Juvenile split correct, Reproductive category eliminated, column completeness, full coverage)
  5. All 144 current org_lifestage values from the existing ECOTOX DB are present in the new dictionary with zero regressions
**Plans:** 2/2 plans complete
Plans:
- [x] 31-01-PLAN.md — Create classifier function + 5-column dictionary tribble with all corrections
- [x] 31-02-PLAN.md — Add assertions, DB validation, diff output, and run validation

### Phase 32: Build Pipeline Integration
**Goal**: Validated dictionary, classifier, and gate logic are wired into the ECOTOX build pipeline and package source in a single mechanical integration
**Depends on**: Phase 31
**Requirements**: GATE-01, GATE-02, GATE-03, GATE-04, INTG-01, INTG-02, INTG-03, INTG-04
**Success Criteria** (what must be TRUE):
  1. Build aborts with `cli::cli_abort()` when a truly unknown lifestage term appears (no keyword match at all)
  2. Build warns with `cli::cli_alert_warning()` and writes keyword-classified terms to `lifestage_review` staging table (never to canonical dictionary)
  3. `.eco_enrich_metadata()` joins only against `lifestage_dictionary` and its relocate call includes the 3 new columns (`ontology_id`, `reproductive_stage`, `classification_source`)
  4. `inst/ecotox/ecotox_build.R` and `data-raw/ecotox.R` section 16 contain identical gate + dictionary logic
  5. `devtools::document()` regenerates man pages without errors after roxygen `@return` updated for new columns
**Plans:** 2/2 plans complete
Plans:
- [x] 32-01-PLAN.md — Replace section 16 in both build scripts with classifier + dictionary + gate
- [x] 32-02-PLAN.md — Update eco_functions.R relocate + roxygen and regenerate man pages

### Phase 33: Build Confirmation
**Goal**: Full ECOTOX build runs successfully with the gate active, producing correct output tables, and the package passes R CMD check
**Depends on**: Phase 32
**Requirements**: VALD-03, VALD-04, VALD-05
**Success Criteria** (what must be TRUE):
  1. Gate correctly aborts for a truly unknown term (e.g., injecting "Xylophage" into test data triggers cli_abort)
  2. Gate correctly warns and quarantines for a keyword-classifiable unmapped term (e.g., "Proto-larva" lands in lifestage_review with correct classification)
  3. `devtools::check()` returns 0 errors after full integration
**Plans:** 2/2 plans complete
Plans:
- [x] 33-01-PLAN.md — Create dev confirmation script and testthat gate regression tests
- [x] 33-02-PLAN.md — Run scoped devtools::check() to confirm 0 errors

## Progress

**Execution Order:**
Phases execute in numeric order: 31 -> 32 -> 33

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-18 | v1.0-v1.9 | 25/25 | Complete | 2026-02-12 |
| 19-21 | v2.0 | 4/4 | Complete | 2026-02-24 |
| 23-26 | v2.1 | 13/13 | Complete | 2026-03-02 |
| 27-30 | v2.2 | 11/11 | Complete | 2026-03-11 |
| 31. Standalone Validation | v2.3 | 2/2 | Complete    | 2026-04-20 |
| 32. Build Pipeline Integration | v2.3 | 2/2 | Complete    | 2026-04-20 |
| 33. Build Confirmation | v2.3 | 2/2 | Complete    | 2026-04-20 |
