# Requirements: ComptoxR

**Defined:** 2026-04-20
**Core Value:** Researchers can query EPA CompTox APIs through stable, well-tested R functions that handle authentication, batching, pagination, and result formatting automatically.

## v2.3 Requirements

Requirements for ECOTOX Lifestage Harmonization. Each maps to roadmap phases.

### Dictionary Schema

- [x] **DICT-01**: Lifestage dictionary expanded to 5 columns: `org_lifestage`, `harmonized_life_stage`, `ontology_id`, `reproductive_stage`, `classification_source`
- [x] **DICT-02**: 7 harmonized categories grounded in UBERON/PO/BODC S11 ontologies (Egg/Embryo, Larva, Juvenile, Subadult, Adult, Senescent/Dormant, Other/Unknown)
- [x] **DICT-03**: `reproductive_stage` boolean flag set independently of developmental classification
- [x] **DICT-04**: All `classification_source` values in canonical dictionary are `"dictionary"`

### Keyword Classifier

- [x] **KWCL-01**: `.classify_lifestage_keywords()` internal function classifies character vector via priority-ordered regex
- [x] **KWCL-02**: Reproductive flag regex fires independently of developmental stage classification
- [ ] **KWCL-03**: Classifier achieves ≥130/144 non-Other/Unknown matches on known descriptions

### Build Gate

- [ ] **GATE-01**: Build aborts with `cli::cli_abort()` when truly unknown terms detected (no keyword match)
- [ ] **GATE-02**: Build warns with `cli::cli_alert_warning()` for keyword-classifiable unmapped terms
- [ ] **GATE-03**: Keyword-classified terms written to `lifestage_review` staging table (not canonical dictionary)
- [ ] **GATE-04**: `.eco_enrich_metadata()` joins only against `lifestage_dictionary`, never `lifestage_review`

### Data Corrections

- [x] **CORR-01**: 6 misclassifications fixed (Germinated seed, Spat, Seed, Sapling, Cocoon, Corm)
- [x] **CORR-02**: Larva/Juvenile split applied (~30 rows reassigned per ontology-backed criteria)
- [x] **CORR-03**: "Reproductive" category eliminated — former terms reclassified to developmental stage with `reproductive_stage = TRUE`

### Integration

- [ ] **INTG-01**: `.eco_enrich_metadata()` relocate call updated to include 3 new columns
- [ ] **INTG-02**: `inst/ecotox/ecotox_build.R` and `data-raw/ecotox.R` section 16 kept in sync
- [ ] **INTG-03**: roxygen `@return` block for `eco_results()` documents new columns
- [ ] **INTG-04**: `devtools::document()` regenerates man pages without errors

### Validation

- [ ] **VALD-01**: Standalone validation script passes all 10 two-axis deterministic assertions
- [ ] **VALD-02**: All 144 current `org_lifestage` values present in new dictionary
- [ ] **VALD-03**: Gate correctly aborts for truly unknown term (e.g., "Xylophage")
- [ ] **VALD-04**: Gate correctly warns and quarantines for keyword-classifiable term (e.g., "Proto-larva")
- [ ] **VALD-05**: `devtools::check()` returns 0 errors after integration

## Future Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### ECOTOX Extended

- **ECOX-01**: Embedding-based classification for novel terms (BioPortal Annotator hybrid layer)
- **ECOX-02**: Automated ontology version tracking and update detection

### Deferred from Previous Milestones

- **ADV-01-04**: Advanced schema handling (content-type extraction, primitive types, nested arrays)
- **S7-01**: S7 class implementation (#29)
- **ADV-TEST-01-04**: Advanced testing (snapshot, performance, contract, data factories)

## Out of Scope

| Feature | Reason |
|---------|--------|
| BioPortal Annotator API integration | Adds API dependency for ~1-3 new terms per release cycle; non-deterministic |
| Embedding-based classification | Dictionary layer is prerequisite; can be added later without breaking static layer |
| Other ECOTOX dictionary expansions (species, media) | Separate milestone scope |
| EPI Suite / GenRA integration | Separate milestone scope |
| Real-time ontology version checking | Static mappings are sufficient for regulatory-grade auditability |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DICT-01 | Phase 31 | Complete |
| DICT-02 | Phase 31 | Complete |
| DICT-03 | Phase 31 | Complete |
| DICT-04 | Phase 31 | Complete |
| KWCL-01 | Phase 31 | Complete |
| KWCL-02 | Phase 31 | Complete |
| KWCL-03 | Phase 31 | Pending |
| GATE-01 | Phase 32 | Pending |
| GATE-02 | Phase 32 | Pending |
| GATE-03 | Phase 32 | Pending |
| GATE-04 | Phase 32 | Pending |
| CORR-01 | Phase 31 | Complete |
| CORR-02 | Phase 31 | Complete |
| CORR-03 | Phase 31 | Complete |
| INTG-01 | Phase 32 | Pending |
| INTG-02 | Phase 32 | Pending |
| INTG-03 | Phase 32 | Pending |
| INTG-04 | Phase 32 | Pending |
| VALD-01 | Phase 31 | Pending |
| VALD-02 | Phase 31 | Pending |
| VALD-03 | Phase 33 | Pending |
| VALD-04 | Phase 33 | Pending |
| VALD-05 | Phase 33 | Pending |

**Coverage:**
- v2.3 requirements: 23 total
- Mapped to phases: 23
- Unmapped: 0

---
*Requirements defined: 2026-04-20*
*Last updated: 2026-04-20 — Traceability updated after roadmap creation*
