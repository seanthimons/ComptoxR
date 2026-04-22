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
- v2.3 ECOTOX Lifestage Harmonization — Phases 31-33 (shipped 2026-04-21)
- **v2.4 Source-Backed Lifestage Resolution** — Phases 34-39 (active)

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

<details>
<summary>v2.3 ECOTOX Lifestage Harmonization (Phases 31-33) — SHIPPED 2026-04-21</summary>

- [x] Phase 31: Standalone Validation (2/2 plans) — completed 2026-04-20
- [x] Phase 32: Build Pipeline Integration (2/2 plans) — completed 2026-04-20
- [x] Phase 33: Build Confirmation (2/2 plans) — completed 2026-04-20

</details>

### v2.4 Source-Backed Lifestage Resolution (Phases 34-39) — ACTIVE

**Milestone Goal:** Replace v2.3 regex-first harmonization with a source-backed ontology resolution pipeline: real OLS4 + NVS provider IDs, committed baseline/derivation CSVs, in-place patch support with 4 refresh modes, and correct 8-column runtime output from `eco_results()`.

- [x] **Phase 34: Teardown** - Remove v2.3 regex classifier, ontology_id column, and purge lifestage tables from DB (completed 2026-04-22)
- [x] **Phase 35: Shared Helper Layer Validation** - Confirm all 14 helper functions in eco_lifestage_patch.R load and behave correctly (OLS4, NVS, BioPortal, scoring) (completed 2026-04-22)
- [ ] **Phase 36: Bootstrap Data Artifacts** - Validate and commit lifestage_baseline.csv and lifestage_derivation.csv with cross-check gate
- [ ] **Phase 37: Build & Patch Integration** - Verify section 16 sync across both build scripts; confirm 4 refresh modes, Windows retry loop, and patch metadata
- [ ] **Phase 38: Runtime API Finalization** - Verify eco_results() exposes 8 new columns, ontology_id is absent, and runtime join targets only lifestage_dictionary
- [ ] **Phase 39: Quality Gates** - Mocked provider tests for OLS4, NVS, and BioPortal adapters; NEWS.md breaking change entry; dev script updates

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

### Phase 34: Teardown
**Goal**: All v2.3 regex artifacts are removed from the codebase and the DB is left in a clean state ready for the new source-backed pipeline
**Depends on**: Phase 33
**Requirements**: TEAR-01, TEAR-02, TEAR-03
**Success Criteria** (what must be TRUE):
  1. No reference to `.classify_lifestage_keywords()` exists anywhere in `R/`, `data-raw/`, or `inst/` after removal
  2. `ontology_id` does not appear in any function signature, roxygen `@return`, column rename, or `relocate()` call in the package source
  3. Running `.eco_patch_lifestage(refresh = "baseline")` on a cold DB creates the `lifestage_dictionary` and `lifestage_review` tables from scratch (confirms purge-on-rebuild path is live)
**Plans**: 1 plan
Plans:
- [x] 34-01-PLAN.md — Verify source tree clean, create purge-and-rebuild script, execute DB rebuild

### Phase 35: Shared Helper Layer Validation
**Goal**: All 14 helper functions in `R/eco_lifestage_patch.R` load cleanly and produce correct output shapes for each adapter and internal stage
**Depends on**: Phase 34
**Requirements**: PROV-01, PROV-02, PROV-03, PROV-04
**Success Criteria** (what must be TRUE):
  1. `devtools::load_all()` completes without errors or warnings attributable to `eco_lifestage_patch.R`
  2. OLS4 adapter post-filters results by `obo_id` prefix (UBERON: or PO:), confirmed by reading the function body or running with a known cross-ontology query
  3. NVS SPARQL adapter returns an empty tibble with a `cli_warn()` (not an abort) when the endpoint is unreachable
  4. BioPortal adapter is invoked only when OLS4 returns unresolved or ambiguous status for a term, never as a first-pass provider
  5. Scoring layer assigns tier scores (100 exact / 90 normalized / 75 token-substring) and correctly classifies candidates into resolved / ambiguous / unresolved status
**Plans**: 2 plans
Plans:
- [x] 35-01-PLAN.md — Fix NVS/OLS4 adapter resilience (tryCatch + cli_warn) and OLS4 prefix post-filter; add PROV-02 unit test
- [x] 35-02-PLAN.md — Create dev/lifestage/validate_35.R validation script exercising all 14 functions with scoring, failure simulation, and live prefix check

### Phase 36: Bootstrap Data Artifacts
**Goal**: Both committed CSV artifacts are complete, internally consistent, and included in the installed package
**Depends on**: Phase 35
**Requirements**: DATA-01, DATA-02, DATA-03
**Success Criteria** (what must be TRUE):
  1. `system.file("extdata/ecotox/lifestage_baseline.csv", package = "ComptoxR")` returns a non-empty path and the file loads as a 13-column tibble covering all distinct `lifestage_codes.description` values in the current ECOTOX release
  2. `system.file("extdata/ecotox/lifestage_derivation.csv", package = "ComptoxR")` returns a non-empty path and the file loads as a 5-column tibble (source_ontology, source_term_id, harmonized_life_stage, reproductive_stage, derivation_source)
  3. Every row in `lifestage_baseline.csv` with `source_match_status == "resolved"` has a matching `(source_ontology, source_term_id)` row in `lifestage_derivation.csv` — cross-check passes with zero gaps
**Plans**: 1 plan
Plans:
- [ ] 34-01-PLAN.md — Verify source tree clean, create purge-and-rebuild script, execute DB rebuild

### Phase 37: Build & Patch Integration
**Goal**: The build path and in-place patch path both produce a correct `lifestage_dictionary`, with Windows-safe connection handling and patch metadata tracked
**Depends on**: Phase 36
**Requirements**: INTG-01, INTG-02, INTG-03, INTG-04
**Success Criteria** (what must be TRUE):
  1. A character diff of section 16 in `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R` returns zero differences (both call shared helpers identically)
  2. `.eco_patch_lifestage(refresh = "auto")` completes on Windows without an `IO Error: Cannot open file` crash, confirmed by the 3-attempt / 200 ms retry loop executing without error under simulated write-connection contention
  3. `.eco_patch_lifestage(refresh = "baseline")` populates `lifestage_dictionary` from the committed CSV without hitting any live API
  4. The `_metadata` table in `ecotox.duckdb` contains a row with version, release, method, and timestamp fields after any patch run
**Plans**: 1 plan
Plans:
- [ ] 34-01-PLAN.md — Verify source tree clean, create purge-and-rebuild script, execute DB rebuild

### Phase 38: Runtime API Finalization
**Goal**: `eco_results()` exposes the new 8-column lifestage output contract; `ontology_id` is absent from all output; the runtime join never touches `lifestage_review`
**Depends on**: Phase 37
**Requirements**: RUNT-01, RUNT-02, RUNT-03
**Success Criteria** (what must be TRUE):
  1. A call to `eco_results()` against a patched DB returns a tibble containing `source_term_id`, `source_term_label`, `source_ontology`, `source_match_status`, `source_match_method`, `harmonized_life_stage`, `reproductive_stage`, and `derivation_source` columns positioned after `organism_lifestage`
  2. `"ontology_id"` is absent from the column names of any `eco_results()` output tibble
  3. The SQL join in `.eco_enrich_metadata()` references `lifestage_dictionary` exclusively — no join or reference to `lifestage_review` exists in the runtime path
  4. `devtools::check()` completes with 0 errors and 0 new warnings after all existing tests are updated for the new column schema
**Plans**: 1 plan
Plans:
- [ ] 34-01-PLAN.md — Verify source tree clean, create purge-and-rebuild script, execute DB rebuild
**UI hint**: no

### Phase 39: Quality Gates
**Goal**: Provider adapters have CI-safe mocked tests; the breaking API change is documented; dev validation scripts reflect the new column layout
**Depends on**: Phase 38
**Requirements**: QUAL-01
**Success Criteria** (what must be TRUE):
  1. `testthat::with_mocked_bindings()` tests exist for OLS4, NVS, and BioPortal adapters, covering both the happy path and the failure/fallback path for each
  2. `NEWS.md` contains a breaking change entry documenting the removal of `ontology_id` from `eco_results()` output
  3. `devtools::test()` runs the mocked adapter tests without hitting any live external API (confirmed by running with no network or API key)
**Plans**: 1 plan
Plans:
- [ ] 34-01-PLAN.md — Verify source tree clean, create purge-and-rebuild script, execute DB rebuild

## Progress

**Execution Order:**
Phases execute in numeric order: 31 -> 32 -> 33 -> 34 -> 35 -> 36 -> 37 -> 38 -> 39

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1-18 | v1.0-v1.9 | 25/25 | Complete | 2026-02-12 |
| 19-21 | v2.0 | 4/4 | Complete | 2026-02-24 |
| 23-26 | v2.1 | 13/13 | Complete | 2026-03-02 |
| 27-30 | v2.2 | 11/11 | Complete | 2026-03-11 |
| 31. Standalone Validation | v2.3 | 2/2 | Complete | 2026-04-20 |
| 32. Build Pipeline Integration | v2.3 | 2/2 | Complete | 2026-04-20 |
| 33. Build Confirmation | v2.3 | 2/2 | Complete | 2026-04-20 |
| 34. Teardown | v2.4 | 1/1 | Complete    | 2026-04-22 |
| 35. Shared Helper Layer Validation | v2.4 | 2/2 | Complete    | 2026-04-22 |
| 36. Bootstrap Data Artifacts | v2.4 | 0/? | Not started | - |
| 37. Build & Patch Integration | v2.4 | 0/? | Not started | - |
| 38. Runtime API Finalization | v2.4 | 0/? | Not started | - |
| 39. Quality Gates | v2.4 | 0/? | Not started | - |
