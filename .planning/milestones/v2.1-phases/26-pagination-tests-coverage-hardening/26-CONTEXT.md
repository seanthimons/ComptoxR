# Phase 26: Pagination Tests & Coverage Hardening - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify pagination functionality with unit and integration tests, and configure coverage thresholds for a codebase with auto-generated stubs. This phase does NOT add new pagination strategies or modify runtime behavior — it tests what exists.

</domain>

<decisions>
## Implementation Decisions

### Pagination Detection Tests (PAG-20)
- Test `detect_pagination()` (dev/endpoint_eval/04_openapi_parser.R) against all 7 registry patterns
- Use **real schema data** extracted from the `schema/` directory at runtime — dynamic scan, not hardcoded snapshots
- Include **negative tests**: feed non-paginated endpoints to confirm no false positives
- If schemas are not present, tests **skip gracefully** with `testthat::skip("schemas not available")`
- Add **warning + 'none' + log** behavior when params look like pagination but don't match any registry pattern (enhancement to `detect_pagination()`)

### Pagination Execution Tests (PAG-21)
- Test each runtime pagination strategy in `generic_request()` with **mocked responses** (not real API calls)
- Strategies to cover: offset_limit (path params), offset_limit (query params), page_number, page_size, cursor
- Mocked tests verify the loop logic, record combination, and termination conditions

### Integration Test (PAG-22)
- Use **chemi_amos_method_pagination** as the VCR-backed integration test endpoint
- Exercise **2-3 pages** to prove the loop works without bloating cassettes
- Verify **last page behavior**: loop terminates correctly on partial/empty page
- Verify **max_pages safety limit**: set max_pages=2, confirm it stops and emits warning

### Coverage Configuration
- **Single threshold: 75%** for entire package
- **Warn only** in CI — report coverage but don't block merges
- **Exclude** `dev/` scripts and `data.R` from coverage measurement

### Test Organization
- **Split by layer** into three files:
  - `test-pagination-detection.R` — regex pattern matching against schemas
  - `test-pagination-execution.R` — mocked runtime strategy tests
  - `test-pagination-integration.R` — VCR-backed end-to-end test
- All files live in `tests/testthat/` (standard R package test directory)
- VCR cassettes follow existing function-name convention (e.g., `chemi_amos_method_pagination.yml`)

### Claude's Discretion
- Exact mock response structure for execution tests
- How to source `dev/` functions in test context (source() vs test helper)
- Whether to use httptest2 or custom mocking for execution tests

</decisions>

<specifics>
## Specific Ideas

- Detection tests should dynamically scan `schema/` directory so they catch drift when schemas are updated
- The warning for unknown pagination patterns should help future developers notice when new EPA endpoints need a new registry entry

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 26-pagination-tests-coverage-hardening*
*Context gathered: 2026-03-01*
