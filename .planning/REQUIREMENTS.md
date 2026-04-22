# Requirements: ComptoxR

**Defined:** 2026-04-22
**Core Value:** Researchers can query EPA CompTox APIs through stable, well-tested R functions that handle authentication, batching, pagination, and result formatting automatically.

## v2.4 Requirements

Requirements for Source-Backed Lifestage Resolution. Each maps to roadmap phases.

### Teardown & Cleanup

- [ ] **TEAR-01**: Remove `.classify_lifestage_keywords()` regex classifier and all references
- [ ] **TEAR-02**: Remove `ontology_id` column from all code paths, docs, and tests
- [ ] **TEAR-03**: Purge `lifestage_dictionary` and `lifestage_review` tables from existing `ecotox.duckdb`; rebuild on-demand via patch

### Provider Resolution

- [ ] **PROV-01**: OLS4 query adapter for UBERON and PO with `obo_id` prefix post-filtering
- [ ] **PROV-02**: NVS SPARQL query adapter for BODC S11 with graceful degradation on endpoint failure
- [ ] **PROV-03**: Scoring/ranking layer (100 exact, 90 normalized, 75 token/substring; resolved/ambiguous/unresolved status)
- [ ] **PROV-04**: BioPortal Annotator as fallback provider when OLS4 returns unresolved or ambiguous terms

### Data Artifacts

- [ ] **DATA-01**: `lifestage_baseline.csv` committed to `inst/extdata/ecotox/` covering current ECOTOX release
- [ ] **DATA-02**: `lifestage_derivation.csv` mapping `source_ontology + source_term_id` to `harmonized_life_stage` and `reproductive_stage`
- [ ] **DATA-03**: Cross-check gate — every resolved baseline row must have a matching derivation row before commit

### Build & Patch Integration

- [ ] **INTG-01**: Build script section 16 in both `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R` calls shared helpers identically
- [ ] **INTG-02**: `.eco_patch_lifestage()` supports 4 refresh modes (auto/cache/baseline/live) for in-place DB patching
- [ ] **INTG-03**: DuckDB Windows write-connection retry loop (3 attempts, 200ms back-off)
- [ ] **INTG-04**: Patch metadata written to `_metadata` table (version, release, method, timestamp)

### Runtime API

- [ ] **RUNT-01**: `eco_results()` exposes 8 new lifestage columns after `organism_lifestage`
- [ ] **RUNT-02**: `ontology_id` absent from all `eco_results()` output
- [ ] **RUNT-03**: Runtime enrichment joins only `lifestage_dictionary`, never `lifestage_review`

### Quality

- [ ] **QUAL-01**: Minimal mocked provider tests via `with_mocked_bindings()` for OLS4, NVS, and BioPortal adapters

## Future Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### ECOTOX Extended

- **ECOX-01**: Automated ontology version tracking and update detection
- **ECOX-02**: Public `.eco_patch_lifestage()` API (currently internal-only)
- **ECOX-03**: NVS `owl:sameAs` to UBERON cross-reference extraction

### Deferred from Previous Milestones

- **ADV-01-04**: Advanced schema handling (content-type extraction, primitive types, nested arrays)
- **S7-01**: S7 class implementation (#29)
- **ADV-TEST-01-04**: Advanced testing (snapshot, performance, contract, data factories)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full test suite for lifestage pipeline | Minimal tests only per user direction |
| Embedding-based classification | Source-backed resolution supersedes regex approach |
| Other ECOTOX dictionary expansions (species, media) | Separate milestone scope |
| EPI Suite / GenRA integration | Separate milestone scope |
| SPARQL-based OLS4 ancestor traversal | Defer to v2.5+ |
| `.planning/phases/01-30` deletion review | Separate review item |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TEAR-01 | Phase 34 | Pending |
| TEAR-02 | Phase 34 | Pending |
| TEAR-03 | Phase 34 | Pending |
| PROV-01 | Phase 35 | Pending |
| PROV-02 | Phase 35 | Pending |
| PROV-03 | Phase 35 | Pending |
| PROV-04 | Phase 35 | Pending |
| DATA-01 | Phase 36 | Pending |
| DATA-02 | Phase 36 | Pending |
| DATA-03 | Phase 36 | Pending |
| INTG-01 | Phase 37 | Pending |
| INTG-02 | Phase 37 | Pending |
| INTG-03 | Phase 37 | Pending |
| INTG-04 | Phase 37 | Pending |
| RUNT-01 | Phase 38 | Pending |
| RUNT-02 | Phase 38 | Pending |
| RUNT-03 | Phase 38 | Pending |
| QUAL-01 | Phase 39 | Pending |

**Coverage:**
- v2.4 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-22*
*Last updated: 2026-04-22 — traceability filled after roadmap creation*
