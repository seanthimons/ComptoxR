# ComptoxR

## What This Is

ComptoxR is an R package providing wrappers for USEPA CompTox Chemical Dashboard APIs. The project encompasses both the automated stub generation pipeline (which produces API wrappers from OpenAPI schemas) and the user-facing package that researchers use for chemical hazard assessment, toxicity screening, and environmental fate analysis.

## Core Value

Researchers can query EPA CompTox APIs through stable, well-tested R functions that handle authentication, batching, pagination, and result formatting automatically.

## Current Milestone: v2.4 Source-Backed Lifestage Resolution

**Goal:** Replace the v2.3 regex-first lifestage harmonization with a source-backed ontology resolution pipeline, adding in-place patch support and real provenance tracking.

**Target features:**
- Tear out v2.3 regex classifier, manual ontology IDs, and 5-column tribble
- OLS4 (UBERON, PO) + NERC NVS (BODC S11) provider resolution with scoring
- 13-column `lifestage_dictionary` with full source provenance chain
- 9-column `lifestage_review` quarantine for ambiguous/unresolved terms
- `.eco_patch_lifestage()` internal function for in-place DB patching without full rebuild
- Release-scoped cache/baseline system with 4 refresh modes (auto/cache/baseline/live)
- Committed baseline CSV for cold-start
- Shared helper layer in `R/eco_lifestage_patch.R`
- Derived fields (`harmonized_life_stage`, `reproductive_stage`) keyed from curated source IDs only
- `eco_results()` updated: new source-backed columns, `ontology_id` removed
- Purge existing lifestage tables from DB; rebuild on-demand

## Current State

**Latest shipped:** v2.3 ECOTOX Lifestage Harmonization (2026-04-21)
**Active:** v2.4 Source-Backed Lifestage Resolution — defining requirements

**Stub generation pipeline (v1.0-v2.1) — ON HOLD:**
The pipeline is fully functional and automated. Resuming pipeline work (advanced schema handling, S7 classes, etc.) is deferred until package stabilization is complete.

Key pipeline capabilities:
- Unified schema parsing for OpenAPI 3.0 and Swagger 2.0 (v1.5-v1.6)
- Auto-pagination engine with 4 strategies (v2.0)
- Metadata-aware test generator (v2.1)
- CI/CD pipeline with automated schema diffing and stub regeneration (v1.8-v2.1)

## Deferred

**Pipeline work (ON HOLD — resume after v2.2):**
- Advanced schema handling (ADV-01-04)
- Advanced testing: snapshot tests, performance benchmarks, contract testing
- S7 class implementation (#29)
- Schema-check workflow improvements (#96)

**Package work (deferred past v2.4):**
- Post-processing recipe system (#120) — defer until concrete need surfaces
- EPI Suite / GenRA integration

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

(Defining for v2.4 — see REQUIREMENTS.md)

### Out of Scope

- Parallel page fetching — rate limits make sequential safer
- Session caching — separate concern
- S7 class implementation — deferred (#29)
- Advanced schema handling — deferred (ADV-01-04)
- httptest2 migration — would require rewriting 706+ cassettes

## Context

**v2.4 context:**
- v2.3 shipped a regex-first lifestage harmonization with manual ontology IDs — approach was wrong, provenance is cosmetic not source-backed
- v2.4 tears out v2.3 implementation and replaces with source-backed ontology resolution via OLS4 + NERC NVS
- Existing lifestage tables purged from DB and rebuilt on-demand
- Target 7 harmonized categories (Egg/Embryo, Larva, Juvenile, Subadult, Adult, Senescent/Dormant, Other/Unknown) but final set adjusts based on provider API results
- Minimal test coverage — no full test suite needed
- Key files: `inst/ecotox/ecotox_build.R`, `data-raw/ecotox.R`, `R/eco_functions.R`, new `R/eco_lifestage_patch.R`
- Implementation plan: LIFESTAGE_HARMONIZATION_PLAN2.md

**Shipped pipeline versions (v1.0-v2.1):**
- v1.0-v1.9: Schema parsing, stub generation, test infrastructure (2026-01-27 to 2026-02-12)
- v2.0: Paginated requests (2026-02-24)
- v2.1: Test infrastructure overhaul (2026-03-02)

**Tech Stack:** R package using httr2, tidyverse, roxygen2, vcr, testthat

## Key Files

- `R/z_generic_request.R` — Core request templates (generic_request, generic_chemi_request, generic_cc_request)
- `R/ct_bioactivity.R` — Complex dispatcher pattern (search_type switch + annotate join)
- `R/ct_lists_all.R` — Post-processing pattern (conditional projection + coerce/split)
- `R/ct_hazard.R` — Thin wrapper pattern (1-line delegation to generated stub)
- `R/ct_details.R` — Direct generic_request() pattern (with projection parameter)
- `dev/endpoint_eval/07_stub_generation.R` — Stub generation logic
- `dev/generate_tests.R` — Test generation script

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
| v2.2 | Package stabilization | Complete |
| v2.3 | ECOTOX Lifestage Harmonization | Complete |
| v2.4 | Source-Backed Lifestage Resolution | Active |

---
*Last updated: 2026-04-22 — Milestone v2.4 started*
