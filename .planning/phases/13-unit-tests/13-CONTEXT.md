# Phase 13: Unit Tests - Context

**Gathered:** 2026-01-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Achieve 80%+ coverage for dev/endpoint_eval/ pipeline code through systematic unit testing. Covers files 00_config.R, 01_schema_resolution.R, 04_openapi_parser.R, and 07_stub_generation.R. Files 02, 03, 05, 06 are covered by integration tests in Phase 14.

</domain>

<decisions>
## Implementation Decisions

### Test organization
- Mirror pipeline files 1:1 (test-pipeline-config.R for 00_config.R, etc.)
- Group tests by function within each file using describe() blocks
- Match existing naming pattern: test-pipeline-*.R for tests, helper-pipeline.R for helpers
- Use global helper cleanup via helper-pipeline.R, not per-test withr::defer()

### Edge case coverage
- Representative samples: one test per edge case type (missing field, null value, wrong type)
- Simple pass/fail for circular reference detection — verify no infinite loop, don't test depth boundaries
- Cover both Swagger 2.0 and OpenAPI 3.0 edge cases with separate fixtures
- For graceful handling, verify "no error" rather than exact return values

### Snapshot strategy
- Use snapshots (expect_snapshot) for generated function stubs
- Capture key parts only: function signature + body structure, not full stub
- VCR cassettes for exported API wrapper functions that make HTTP calls
- Snapshots for internal/non-exported function testing
- Use testthat default _snaps/ location

### Coverage thresholds
- 80% coverage is a guideline, not a hard requirement
- Test in dependency order: schema resolution (01) → parsing (04) → generation (07)
- Skip dedicated unit tests for files 02, 03, 05, 06 (covered by Phase 14 integration)
- Thorough coverage for 00_config.R despite simplicity — test all edge cases for %||%, ensure_cols()

### Claude's Discretion
- Exact number of test cases per function
- Fixture file naming within the established pattern
- Error message wording in test descriptions

</decisions>

<specifics>
## Specific Ideas

- Dependency chain insight: "Schema parsing failing implies stub generation fails implies production functions fail" — test foundational functions first to catch failures at source
- Tests should surface problems at the source, not as downstream symptoms

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 13-unit-tests*
*Context gathered: 2026-01-30*
