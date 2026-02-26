# ComptoxR Stub Generation Pipeline

## What This Is

ComptoxR's automated function stub generation pipeline for EPA CompTox API wrappers. The pipeline parses OpenAPI schemas and generates R functions with correct signatures, documentation, and request handling.

## Core Value

Generated API wrapper functions must send requests in the format the API expects — correct body encoding, content types, and parameter handling.

## Current State

**Latest shipped:** v1.9 Schema Check Workflow Fix (2026-02-12)

The stub generation pipeline is fully documented, consolidated, and tested:
- Query parameter extraction and function signatures (v1.0)
- Raw text body support for `/chemical/search/equal/` (v1.1)
- JSON array encoding for bulk POST endpoints (v1.2)
- Correct resolver integration with idType parameter (v1.3)
- Empty POST endpoint detection and reporting (v1.4)
- Swagger 2.0 body-in-parameters extraction (v1.5)
- Version-aware reference resolution with fallback chain (v1.5)
- Preflight endpoint filtering (v1.5)
- Unified `openapi_to_spec()` pipeline for all schema types (v1.6)
- `select_schema_files()` helper for stage-based prioritization (v1.6)
- Removed `parse_chemi_schemas()` redundancy (v1.6)
- Updated ENDPOINT_EVAL_UTILS_GUIDE.md with comprehensive documentation (v1.7)
- Comprehensive test infrastructure with 95+ test cases (v1.8)
- E2E integration tests for full schema -> stub -> execution flow (v1.8)
- CI/CD pipeline with coverage thresholds (R/ >=75%, dev/ >=80%) (v1.8)
- Codecov integration for coverage tracking (v1.8)
- Fixed unicode_map CI dependency issue (v1.9)
- Endpoint-level schema diffing with breaking change detection (v1.9)
- Timeout protection and graceful failure handling (v1.9)

## Current Milestone: v2.1 Test Infrastructure

**Goal:** Fix build blockers, rebuild test generation to produce correct tests for every function, and automate the stub-to-test pipeline with CI reporting.

**Target features:**
- Fix build errors (bad stub code, duplicate args, dependency mismatches)
- Rebuild test generator to respect actual parameter types and tidy flags
- Nuke bad VCR cassettes and re-record from production with correct params
- Generate tests for every exported function targeting high coverage
- Pagination-specific tests (carried from v2.0 Phase 22)
- Local dev script + CI workflow for automated test generation on new stubs
- CI reporting: logs, progress reports, coverage enforcement

## Deferred

Future milestones:
- Advanced schema handling (ADV-01-04)

## Requirements

### Validated

- Query parameters from OpenAPI specs appear in generated function signatures — v1.0
- Generated functions work correctly when called with query parameters — v1.0
- All affected stubs regenerated with correct signatures — v1.0
- OpenAPI schema parsing extracts endpoint metadata — existing
- Generic request templates handle HTTP communication — existing
- Stub generation produces R functions with roxygen documentation — existing
- `devtools::document()` generates man pages from stubs — existing
- Special case handling for `/chemical/search/equal/` POST endpoint — v1.1
- `generic_request()` supports `body_type` parameter for raw text encoding — v1.1
- `ct_chemical_search_equal_bulk()` sends correct request format via `generic_request()` — v1.1
- Bulk POST endpoints with `string_array` body send JSON arrays — v1.2
- Only `/chemical/search/equal/` endpoint uses raw text body encoding — v1.2
- All 26 affected bulk stubs regenerated with correct body handling — v1.2
- Live API verification confirms JSON encoding works correctly — v1.2
- Generated resolver calls use `idType` parameter (camelCase) — v1.3
- Generated code handles resolver list return type correctly — v1.3
- "AnyId" default passed via idType parameter — v1.3
- POST endpoints with no params + empty body are skipped during generation — v1.4
- User sees cli warnings for each skipped endpoint — v1.4
- Summary report shown at end of generation run — v1.4
- GET endpoints with no parameters still generate correctly — v1.4
- Parser detects Swagger 2.0 via `swagger` field at root — v1.5
- Parser detects OpenAPI 3.0 via `openapi` field at root — v1.5
- Version detection routes to appropriate extraction logic — v1.5
- Swagger 2.0 body extracted from `parameters[].in="body"` — v1.5
- Swagger 2.0 `#/definitions/` references resolved correctly — v1.5
- OpenAPI 3.0 `#/components/schemas/` references resolved correctly — v1.5
- Version-aware fallback chain for reference resolution — v1.5
- Nested reference resolution with depth limit 3 — v1.5
- Preflight endpoints filtered from generation — v1.5
- AMOS, RDKit, Mordred stub generation capability verified — v1.5
- OpenAPI 3.0 parsing unchanged (no regression) — v1.5
- `generate_chemi_stubs()` uses `openapi_to_spec()` directly — v1.6
- All three generators (ct, chemi, cc) follow identical parsing pattern — v1.6
- `ENDPOINT_PATTERNS_TO_EXCLUDE` applied consistently across all schema types — v1.6
- Version detection works for all schemas via unified pipeline — v1.6
- `parse_chemi_schemas()` removed from codebase — v1.6
- Code duplication reduced via `select_schema_files()` helper — v1.6
- All existing stubs regenerate correctly (no regression) — v1.6
- Chemi stubs benefit from v1.5 Swagger 2.0 body extraction — v1.6

### Active

- Fix build errors blocking R CMD check
- Rebuild test generator with correct parameter type detection
- Re-record VCR cassettes from production with correct params
- Test coverage for all exported API wrapper functions
- Pagination-specific tests (Phase 22 carry-forward)
- Automated stub-to-test pipeline (local + CI)
- CI logs and progress reporting

### Out of Scope

- Adding new API endpoints — focus is test infrastructure, not coverage expansion
- Parallel page fetching — rate limits make sequential safer
- Session caching — separate concern
- S7 class implementation — deferred
- Advanced schema handling — deferred

## Context

**Shipped Versions:**
- v1.0: Query parameter signatures (2026-01-27)
- v1.1: Raw text body fix (2026-01-27)
- v1.2: Bulk request body type fix (2026-01-28)
- v1.3: Chemi resolver integration fix (2026-01-28)
- v1.4: Empty POST endpoint detection (2026-01-29)
- v1.5: Swagger 2.0 body schema support (2026-01-29)
- v1.6: Unified stub generation pipeline (2026-01-30)
- v1.7: Documentation refresh (2026-01-29)
- v1.8: Testing infrastructure (2026-01-31)
- v1.9: Schema check workflow fix (2026-02-12)

**Tech Stack:** R package using httr2, tidyverse, roxygen2

## Key Files

- `R/z_generic_request.R` — Core request templates (generic_request, generic_chemi_request, generic_cc_request)
- `dev/endpoint_eval/07_stub_generation.R` — Stub generation logic
- `R/ct_chemical_search_equal.R` — Example of generated raw text body stub
- `R/chemi_resolver_lookup.R` — Resolver function for chemical identifiers

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use "query" as synthetic param name | Consistent with path parameter pattern | Good |
| Return type="string_array" not "array" | Enables type-specific handling | Good |
| Set required=TRUE for body params | Body typically required for POST | Good |
| Add inline schema detection | Schemas can be inline without $ref | Good |
| Use Sys.getenv for batch_limit | Runtime configurability | Good |
| Three-cassette VCR strategy | Clear test organization | Good |
| Extend generic_request() for body_type | Function inherits debug/verbose/batching | Good |
| Endpoint-specific raw text detection | Only /chemical/search/equal/ needs raw text | Good |
| Pass query directly for string_array | generic_request() handles JSON encoding | Good |
| Use camelCase idType parameter | Must match chemi_resolver_lookup() signature | Good |
| Handle resolver return as list | Resolver returns list with tidy=FALSE | Good |
| Detection after ensure_cols() | Run detection before parameter parsing | Good |
| Use .StubGenEnv for tracking | Cross-call state accumulation | Good |
| Log files to dev/logs/ | Standard location for generation artifacts | Good |
| Check swagger/openapi root fields | Reliable version detection | Good |
| Version-aware fallback chain | Handles both definition locations | Good |
| Depth limit 3 for nested refs | Prevents infinite recursion | Good |
| Capability verification for stubs | Proves pipeline works without file pollution | Good |
| Remove aggressive component filtering | Prevents nested reference failures | Good |
| Extract select_schema_files() helper | Reusable stage-based file selection | Good |
| Unify chemi to use openapi_to_spec() | Consistent version detection and body extraction | Good |
| Delete parse_chemi_schemas() | Single source of truth, -130 lines | Good |

## Milestones

| Version | Description | Status |
|---------|-------------|--------|
| v1.0 | Query parameter signatures | Complete |
| v1.1 | Raw text body fix | Complete |
| v1.2 | Bulk request body type fix | Complete |
| v1.3 | Chemi resolver integration fix | Complete |
| v1.4 | Empty POST endpoint detection | Complete |
| v1.5 | Swagger 2.0 body schema support | Complete |
| v1.6 | Unified stub generation pipeline | Complete |
| v1.7 | Documentation refresh | Complete |
| v1.8 | Testing infrastructure | Complete |
| v1.9 | Schema check workflow fix | Complete |
| v2.0 | Paginated requests | Complete |
| v2.1 | Test infrastructure | In Progress |

---
*Last updated: 2026-02-26 after v2.1 milestone started*
