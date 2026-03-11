# Project Milestones: ComptoxR Stub Generation Pipeline

## v2.1 Test Infrastructure (Shipped: 2026-03-02)

**Delivered:** Complete test infrastructure overhaul — fixed build blockers, rebuilt test generator with metadata awareness, automated stub-to-test pipeline with CI integration, and added pagination test coverage.

**Phases completed:** 23-26 (4 phases, 13 plans)

**Key accomplishments:**

- Fixed all build blockers — R CMD check 0 errors (8 BUILD fixes, 230 stubs regenerated from fixed generator)
- Built metadata-aware test generator reading actual function signatures and tidy flags
- Deleted 673 bad VCR cassettes, created parallel re-recording script with mirai (8 workers)
- Created automated test gap detection + generation pipeline integrated into schema-check CI
- Added 102 pagination tests (72 detection, 20 mocked execution, 10 VCR integration)
- Configured 75% coverage threshold (warn-only) with Codecov integration

**Stats:**

- 43 commits over 4 days (2026-02-26 → 2026-03-01)
- 4 phases, 13 plans
- All 30 requirements satisfied (BUILD-01..08, TGEN-01..05, VCR-01..07, AUTO-01..06, PAG-20..23)

**Tech debt (non-blocking):**
- purrr::flatten warning persists on package load
- Re-recording script built but not executed (requires API key)
- Only 33 of 256 API wrappers have recorded cassettes
- 297 pre-existing test failures from VCR/API key issues (not caused by v2.1)

**What's next:** Advanced testing features (snapshot tests, performance benchmarks, contract testing)

---

## v2.0 Paginated Requests (Shipped: 2026-02-24)

**Delivered:** Auto-pagination engine for all CompTox API request templates, supporting offset/limit, page/size, cursor, and path-based strategies

**Phases completed:** 19-21 (3 phases, 4 plans)

**Key accomplishments:**

- Implemented pagination pattern detection from OpenAPI schemas (5 regex patterns)
- Built auto-pagination engine in generic_request(), generic_chemi_request(), and generic_cc_request()
- Added 4 pagination strategies: offset/limit, page/size, cursor-based, path-based (AMOS)
- Integrated pagination into stub generation — stubs auto-paginate by default
- Added max page count (100), configurable delay, progress feedback via cli

**What's next:** Test coverage for pagination (carried to v2.1 Phase 26)

---

## v1.9 Schema Check Workflow Fix (Shipped: 2026-02-12)

**Delivered:** Fixed CI/CD schema check workflow with endpoint-level diffing, breaking change detection, and reliability improvements

**Phases completed:** 16-18 (3 phases, 4 plans)

**Key accomplishments:**

- Fixed unicode_map CI dependency issue
- Implemented endpoint-level schema diffing with breaking change detection
- Added timeout protection and graceful failure handling
- All SCHEMA-01-04 requirements satisfied

**What's next:** Paginated requests (v2.0)

---

## v1.8 Testing Infrastructure (Shipped: 2026-01-31)

**Delivered:** Comprehensive test coverage for stub generation pipeline, enabling CRAN/rOpenSci release readiness

**Phases completed:** 12-15 (6 plans total)

**Key accomplishments:**

- Created test infrastructure with helper-pipeline.R (5 utility functions), 4 JSON fixtures, withr dependency
- Developed 95+ unit tests covering config, schema resolution, OpenAPI parsing, and stub generation
- Built E2E integration tests validating full pipeline from production schemas to executable functions
- Implemented CI/CD pipeline with GHA workflow, coverage thresholds (R/ ≥75%, dev/ ≥80%), Codecov integration
- Closed gap from initial audit: added get_stubgen_config() helper and fixed cassette path
- All 8 requirements satisfied (FR-01-05, NFR-01-03)

**Stats:**

- 17 files created/modified
- 2,146 lines of test code
- 4 phases, 6 plans
- 2 days (2026-01-30 to 2026-01-31)

**Git range:** `88ffc1c` → `ff174d0` (12 commits)

**What's next:** Consider expanding test coverage to additional endpoints; prepare for CRAN submission

---

## v1.7 Documentation Refresh (Shipped: 2026-01-29)

**Delivered:** Updated ENDPOINT_EVAL_UTILS_GUIDE.md to reflect v1.5-v1.6 pipeline changes, documenting unified architecture and Swagger 2.0 support

**Phases completed:** 11 (1 plan total)

**Key accomplishments:**

- Removed all references to deleted `parse_chemi_schemas()` function
- Documented `select_schema_files()` helper with usage examples
- Updated Architecture Overview for unified `openapi_to_spec()` pipeline
- Updated Mermaid flowcharts to show single processing path
- Added comprehensive Swagger 2.0 handling section
- Updated developer guidance sections with v1.5-v1.6 context
- All 18 requirements satisfied (DOC-01-15, VAL-01-03)

**Stats:**

- 2 files modified
- ~320 lines changed in documentation
- 1 phase, 1 plan, 3 tasks
- Same day (2026-01-29)

**Git range:** `f905846` → `6671966`

---

## v1.6 Unified Stub Generation Pipeline (Shipped: 2026-01-30)

**Delivered:** Consolidated all three stub generators (ct, chemi, cc) to use `openapi_to_spec()` directly, eliminating the divergent `parse_chemi_schemas()` code path

**Phases completed:** 10 (1 plan total)

**Key accomplishments:**

- Unified `generate_chemi_stubs()` to call `openapi_to_spec()` directly (matching ct/cc pattern)
- Extracted `select_schema_files()` helper for reusable stage-based file prioritization
- Removed `parse_chemi_schemas()` function (~130 lines of duplicate code)
- Ensured consistent version detection across all three generators
- Added guard clauses for edge cases (empty stub results)
- All 8 in-scope requirements satisfied (UNIFY-01-04, CLEAN-01-02, VAL-02-03)

**Stats:**

- 2 files modified
- Net -63 lines (75 added, 138 removed)
- 1 phase, 1 plan, 2 tasks
- Same day (2026-01-29 to 2026-01-30)

**Git range:** `4531b03` → `a73dcc3`

---

## v1.5 Swagger 2.0 Body Schema Support (Shipped: 2026-01-29)

**Delivered:** Added support for Swagger 2.0 schemas (AMOS, RDKit, Mordred) with version detection, body-in-parameters extraction, and version-aware reference resolution

**Phases completed:** 7-9 (5 plans total)

**Key accomplishments:**

- Implemented `detect_schema_version()` for automatic Swagger 2.0 vs OpenAPI 3.0 detection
- Added `extract_swagger2_body_schema()` for `parameters[].in="body"` extraction
- Enhanced `resolve_schema_ref()` with version-aware fallback chain (`#/definitions/` and `#/components/schemas/`)
- Added preflight endpoint filtering via `ENDPOINT_PATTERNS_TO_EXCLUDE`
- Created comprehensive verify_phase9.R testing 5 schemas (3 Swagger 2.0, 2 OpenAPI 3.0)
- All 19 requirements satisfied (VERS-01-03, BODY-01-06, REF-01-03, FILT-01, INTEG-01-06)

**Stats:**

- 4 files modified
- ~600 lines of R added
- 3 phases, 5 plans
- Same day (2026-01-29)

---

## v1.4 Empty POST Endpoint Detection (Shipped: 2026-01-29)

**Delivered:** Added detection and reporting for POST endpoints with incomplete schemas (no params, empty body), skipping them during stub generation with user notification

**Phases completed:** 6 (1 plan total)

**Key accomplishments:**

- Implemented `is_empty_post_endpoint()` detection function with comprehensive schema analysis
- Integrated detection into `render_endpoint_stubs()` with automatic filtering and tracking
- Added styled CLI reporting with log file output for skipped/suspicious endpoints
- Updated `dev/generate_stubs.R` to call tracking reset and report functions
- All 9 requirements satisfied (DETECT-01 through DETECT-04, NOTIFY-01 through NOTIFY-03, SCOPE-01, SCOPE-02)

**Stats:**

- 2 files modified
- 247 lines of R added
- 1 phase, 1 plan, 3 tasks
- Same day (2026-01-29)

**Git range:** `c5bdf96` → `a8531d7`

---

## v1.3 Chemi Resolver Integration Fix (Shipped: 2026-01-28)

**Delivered:** Fixed stub generation template to call chemi_resolver_lookup with correct parameter naming (idType) and list handling

**Phases completed:** 5 (1 plan total)

**Key accomplishments:**

- Fixed parameter naming from id_type to idType in resolver template (matches function signature)
- Fixed list handling to use length() instead of nrow() for emptiness check
- Fixed list iteration to use purrr::map() instead of tibble row access
- Fixed existing chemi_cluster.R resolver call with correct parameter name
- All 4 requirements satisfied (STUB-01, STUB-02, STUB-03, VAL-01)

**Stats:**

- 2 files modified
- 32 lines changed (15 insertions, 17 deletions)
- 1 phase, 1 plan, 4 tasks
- Same day (2026-01-28)

**Git range:** `72f33c4` → `6ab15e9`

---

## v1.2 Bulk Request Body Type Fix (Shipped: 2026-01-28)

**Delivered:** Fixed stub generation to use JSON arrays for bulk POST endpoints, preserving raw text only for `/chemical/search/equal/`

**Phases completed:** 4 (3 plans total)

**Key accomplishments:**

- Fixed stub generation to use JSON encoding for string_array body types
- Added endpoint-specific detection for `/chemical/search/equal/` raw text
- Regenerated 26 bulk POST functions with correct body encoding
- Preserved exception case (`ct_chemical_search_equal_bulk`) with raw text
- Live API verification confirmed JSON encoding works correctly
- Added VCR tests for regression testing

**Stats:**

- 236 files modified
- ~6,957 lines of R added
- 1 phase, 3 plans, ~7 tasks
- 1 day from start to ship

**Git range:** `15cde53` → `fab336c`

---

## v1.1 Raw Text Body Fix (Shipped: 2026-01-27)

**Delivered:** Added raw text body support for `/chemical/search/equal/` POST endpoint

**Phases completed:** 3 (2 plans total)

**Key accomplishments:**

- Extended `generic_request()` with `body_type` parameter supporting "json" and "raw_text"
- Updated stub generator to detect string body type POST endpoints
- Regenerated `ct_chemical_search_equal_bulk()` with proper raw text encoding
- Function inherits debug, verbose, batching, and error handling

**Stats:**

- ~50 files modified
- 1 phase, 2 plans
- ~1 day from start to ship

---

## v1.0 Stub Generation Fix (Shipped: 2026-01-27)

**Delivered:** Fixed POST endpoint stub generation so simple body schemas (string, string_array) correctly generate function signatures with query parameters

**Phases completed:** 1-2 (4 plans total)

**Key accomplishments:**

- Enhanced `extract_body_properties()` to handle simple string and string_array body schemas
- Updated `build_function_stub()` to generate correct function signatures with query parameters
- Implemented newline collapsing for string array inputs
- Added runtime-configurable batch limits via `Sys.getenv("batch_limit")`
- Added inline schema detection for OpenAPI specs without $ref
- Validated `ct_chemical_search_equal_bulk()` against live CompTox API with VCR cassettes

**Stats:**

- 12 files modified
- ~530 lines of R added
- 2 phases, 4 plans, ~11 tasks
- ~2 hours from start to ship

**Git range:** `feat(01-01)` → `test(02-02)` (commits 803ea2c → de5a966)

---
