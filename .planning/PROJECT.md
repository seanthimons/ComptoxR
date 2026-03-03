# ComptoxR Stub Generation Pipeline

## What This Is

ComptoxR's automated function stub generation pipeline for EPA CompTox API wrappers. The pipeline parses OpenAPI schemas and generates R functions with correct signatures, documentation, and request handling.

## Core Value

Generated API wrapper functions must send requests in the format the API expects — correct body encoding, content types, and parameter handling.

## Current State

**Latest shipped:** v2.1 Test Infrastructure (2026-03-02)

The stub generation pipeline is fully documented, consolidated, tested, and automated:
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
- Updated ENDPOINT_EVAL_UTILS_GUIDE.md with comprehensive documentation (v1.7)
- Comprehensive test infrastructure with 95+ test cases (v1.8)
- E2E integration tests for full schema -> stub -> execution flow (v1.8)
- CI/CD pipeline with coverage thresholds and Codecov integration (v1.8)
- Endpoint-level schema diffing with breaking change detection (v1.9)
- Timeout protection and graceful failure handling (v1.9)
- Auto-pagination engine for all request templates (v2.0)
- 4 pagination strategies: offset/limit, page/size, cursor, path-based (v2.0)
- R CMD check 0 errors — all build blockers fixed (v2.1)
- Metadata-aware test generator reading function signatures and tidy flags (v2.1)
- VCR cassette cleanup with parallel re-recording script (v2.1)
- Automated test gap detection + generation pipeline in CI (v2.1)
- 102 pagination tests (detection, execution, integration) (v2.1)
- 75% coverage threshold (warn-only) with Codecov (v2.1)

## Deferred

Future milestones:
- Advanced schema handling (ADV-01-04)
- Advanced testing: snapshot tests, performance benchmarks, contract testing
- S7 class implementation (#29)
- Schema-check workflow improvements (#96)

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
- Auto-pagination engine for offset/limit, page/size, cursor, path-based strategies — v2.0
- Pagination pattern detection from OpenAPI schemas — v2.0
- Generated stubs auto-paginate by default — v2.0
- R CMD check produces 0 errors after build fixes — v2.1
- Test generator reads actual parameter names/types from function signatures — v2.1
- Test generator reads tidy flag from generic_request() calls — v2.1
- VCR cassette management helpers (delete, list, check_safety) — v2.1
- Automated test gap detection + generation pipeline in CI — v2.1
- 102 pagination tests (detection, execution, integration) — v2.1
- 75% coverage threshold (warn-only) with Codecov — v2.1

### Active

(None — define next milestone with `/gsd:new-milestone`)

### Out of Scope

- Parallel page fetching — rate limits make sequential safer
- Session caching — separate concern
- S7 class implementation — deferred (#29)
- Advanced schema handling — deferred (ADV-01-04)
- httptest2 migration — would require rewriting 706+ cassettes

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
| v2.1 | Test infrastructure | Complete |

---
*Last updated: 2026-03-02 after v2.1 milestone completed*
