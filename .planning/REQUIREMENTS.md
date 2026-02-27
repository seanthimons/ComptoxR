# Requirements: ComptoxR v2.1 Test Infrastructure

**Defined:** 2026-02-26
**Core Value:** Every exported function has a correct, passing test — and the pipeline keeps it that way automatically.

## v2.1 Requirements

### Build Fixes

- [x] **BUILD-01**: R CMD check produces 0 errors after fixing stub generator syntax bugs (`"RF" <- model = "RF"`, duplicate `endpoint` args)
- [x] **BUILD-02**: All unused/undeclared imports resolved (devtools, magick, usethis removed or moved to Suggests; ggplot2, janitor removed from Imports)
- [x] **BUILD-03**: Non-ASCII characters in `R/extract_mol_formula.R` replaced with `\uxxxx` escapes
- [x] **BUILD-04**: `jsonlite::flatten` vs `purrr::flatten` import collision resolved
- [x] **BUILD-05**: httr2 compatibility fixed — either update minimum version or replace missing `resp_is_transient`/`resp_status_class` calls
- [x] **BUILD-06**: Roxygen `@param` documentation matches actual function signatures across all generated stubs
- [x] **BUILD-07**: Non-standard license in DESCRIPTION replaced with valid CRAN-compatible license specification
- [x] **BUILD-08**: Partial argument match `body` → `body_type` fixed in `ct_chemical_msready_by_mass` and `ct_chemical_msready_search_by_mass_bulk`

### Test Generator

- [x] **TGEN-01**: Test generator reads actual parameter names and types from function signatures, mapping each to appropriate test values (DTXSID for query, integer for limit, string for search_type, etc.)
- [x] **TGEN-02**: Test generator reads `tidy` flag from `generic_request()`/`generic_chemi_request()` calls and asserts list or tibble accordingly
- [x] **TGEN-03**: Test generator handles functions with no parameters (static endpoints) by generating parameterless test calls
- [x] **TGEN-04**: Test generator handles functions with `path_params` by generating appropriate test values per parameter name
- [x] **TGEN-05**: Generated tests use unique cassette names per test variant (single, batch, error, example) to enable isolated re-recording

### Pagination Tests (carried from v2.0 Phase 22)

- [ ] **PAG-20**: Unit tests verify regex detection catches all 5 known pagination patterns from real schemas
- [ ] **PAG-21**: Unit tests verify each pagination strategy (offset/limit, page/size, cursor, path-based) with mocked responses
- [ ] **PAG-22**: At least one integration test runs a paginated stub end-to-end with VCR cassettes
- [ ] **PAG-23**: All existing non-pagination tests continue to pass (no regression)

### VCR Cassette Management

- [ ] **VCR-01**: All 673 untracked cassettes recorded with wrong parameters are deleted
- [x] **VCR-02**: `delete_all_cassettes()` function implemented in helper-vcr.R for bulk cassette deletion
- [x] **VCR-03**: `delete_cassettes(pattern)` function implemented for pattern-based cassette deletion
- [x] **VCR-04**: `list_cassettes()` function implemented to enumerate existing cassettes
- [x] **VCR-05**: `check_cassette_safety()` function implemented to scan cassettes for leaked API keys
- [ ] **VCR-06**: Security audit confirms all committed cassettes are API-key filtered (show `<<<API_KEY>>>` not actual keys)
- [x] **VCR-07**: Cassette re-recording script supports batched execution (20-50 at a time) with rate-limit delays

### Automation & CI

- [ ] **AUTO-01**: `dev/detect_test_gaps.R` script identifies functions in R/ without corresponding test files
- [ ] **AUTO-02**: `dev/generate_tests.R` script generates tests for all detected gaps using the fixed test generator
- [ ] **AUTO-03**: GitHub Action workflow detects new/changed stubs and generates corresponding test files
- [ ] **AUTO-04**: CI reports test gap count and coverage metrics in workflow summary
- [ ] **AUTO-05**: Coverage thresholds tuned for generated code (exclude auto-generated stubs from strict thresholds or use tiered rates)
- [ ] **AUTO-06**: Test generation is integrated into stub generation pipeline — running `dev/generate_stubs.R` followed by `dev/generate_tests.R` produces matched stub+test pairs

## v2.0 Requirements (validated)

### Pagination Pattern Detection — shipped Phase 19

- [x] **PAG-01**: Stub generator detects pagination parameters using regex patterns
- [x] **PAG-02**: Detection patterns are configurable via a central registry
- [x] **PAG-03**: Detected pagination metadata stored in endpoint spec
- [x] **PAG-04**: Stub generator classifies endpoints into pagination strategies

### Auto-Pagination in Request Templates — shipped Phases 20-21

- [x] **PAG-05**: `generic_request()` accepts `paginate` parameter
- [x] **PAG-06**: `generic_chemi_request()` accepts `paginate` parameter
- [x] **PAG-07**: `generic_cc_request()` accepts `paginate` parameter
- [x] **PAG-08**: Offset/limit pagination auto-increments
- [x] **PAG-09**: Page/size pagination auto-increments
- [x] **PAG-10**: Cursor-based pagination follows tokens
- [x] **PAG-11**: Path-based AMOS pagination increments offset
- [x] **PAG-12**: All strategies combine results into single tibble/list
- [x] **PAG-13**: Progress feedback via cli in verbose mode
- [x] **PAG-14**: Generated stubs call with `paginate = TRUE` by default
- [x] **PAG-15**: Generated stubs retain individual pagination params
- [x] **PAG-16**: Generated stubs include `all_pages` parameter
- [x] **PAG-17**: Max page count (default 100) prevents runaway loops
- [x] **PAG-18**: Sequential requests with configurable delay
- [x] **PAG-19**: Empty/error responses stop loop gracefully

## Future Requirements

### Advanced Testing (v2.2+)

- **ADV-TEST-01**: Snapshot testing for complex return structures
- **ADV-TEST-02**: Performance benchmarking tests for pagination
- **ADV-TEST-03**: Contract testing for API versioning
- **ADV-TEST-04**: Test data factories for parameterized inputs at scale

### Deferred from Previous Milestones

- **ADV-01-04**: Advanced schema handling (content-type extraction, primitive types, nested arrays)
- **S7-01**: S7 class implementation (#29)
- **SCHEMA-01-04**: Schema-check workflow improvements (#96)

## Out of Scope

| Feature | Reason |
|---------|--------|
| New API endpoint wrappers | Focus is test infrastructure, not coverage expansion |
| httptest2 migration | Would require rewriting 706+ cassettes; vcr is working |
| xpectr/patrick adoption | Custom generator already tailored to API wrapper patterns |
| Parallel page fetching | Rate limits make sequential safer; separate concern |
| 100% test coverage | Diminishing returns above 90%; target high coverage badge |
| Live API testing in CI | Use VCR cassettes; scheduled weekly validation is separate |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BUILD-01 | Phase 23 | Complete |
| BUILD-02 | Phase 23 | Complete |
| BUILD-03 | Phase 23 | Complete |
| BUILD-04 | Phase 23 | Complete |
| BUILD-05 | Phase 23 | Complete |
| BUILD-06 | Phase 23 | Complete |
| BUILD-07 | Phase 23 | Complete |
| BUILD-08 | Phase 23 | Complete |
| TGEN-01 | Phase 23 | Complete |
| TGEN-02 | Phase 23 | Complete |
| TGEN-03 | Phase 23 | Complete |
| TGEN-04 | Phase 23 | Complete |
| TGEN-05 | Phase 23 | Complete |
| VCR-01 | Phase 24 | Pending |
| VCR-02 | Phase 24 | Complete |
| VCR-03 | Phase 24 | Complete |
| VCR-04 | Phase 24 | Complete |
| VCR-05 | Phase 24 | Complete |
| VCR-06 | Phase 24 | Pending |
| VCR-07 | Phase 24 | Complete |
| AUTO-01 | Phase 25 | Pending |
| AUTO-02 | Phase 25 | Pending |
| AUTO-03 | Phase 25 | Pending |
| AUTO-04 | Phase 25 | Pending |
| AUTO-05 | Phase 25 | Pending |
| AUTO-06 | Phase 25 | Pending |
| PAG-20 | Phase 26 | Pending |
| PAG-21 | Phase 26 | Pending |
| PAG-22 | Phase 26 | Pending |
| PAG-23 | Phase 26 | Pending |

**Coverage:**
- v2.1 requirements: 30 total
- Mapped to phases: 30 ✓
- Unmapped: 0 ✓

**Validation:**
- All BUILD requirements (8) → Phase 23
- All TGEN requirements (5) → Phase 23
- All VCR requirements (7) → Phase 24
- All AUTO requirements (6) → Phase 25
- All PAG requirements (4) → Phase 26

---
*Requirements defined: 2026-02-26*
*Last updated: 2026-02-26 after roadmap creation*
