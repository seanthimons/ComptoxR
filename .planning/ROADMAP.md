# Roadmap: ComptoxR v2.0 Paginated Requests

## Overview

Add automatic pagination to all EPA API endpoints. Paginated functions transparently fetch all pages and return combined results. The stub generator detects pagination patterns via regex and generates auto-paginating wrapper code. Users call a function once and get everything back.

## Milestones

- v1.0 Stub Generation Fix - Phases 1-2 (shipped 2026-01-27)
- v1.1 Raw Text Body Fix - Phase 3 (shipped 2026-01-27)
- v1.2 Bulk Request Body Type Fix - Phase 4 (shipped 2026-01-28)
- v1.3 Chemi Resolver Integration Fix - Phase 5 (shipped 2026-01-28)
- v1.4 Empty POST Endpoint Detection - Phase 6 (shipped 2026-01-29)
- v1.5 Swagger 2.0 Body Schema Support - Phases 7-9 (shipped 2026-01-29)
- v1.6 Unified Stub Generation Pipeline - Phase 10 (shipped 2026-01-30)
- v1.7 Documentation Refresh - Phase 11 (shipped 2026-01-29)
- v1.8 Testing Infrastructure - Phases 12-15 (shipped 2026-01-31)
- v1.9 Schema Check Workflow Fix - Phases 16-18 (shipped 2026-02-12)
- **v2.0 Paginated Requests** - Phases 19-22 (current)

## Phases

**Phase Numbering:**
- Integer phases (19, 20, 21, 22): Planned milestone work
- Decimal phases (19.1, 19.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 19: Pagination Detection** - Detect and classify pagination patterns in OpenAPI schemas
- [ ] **Phase 20: Auto-Pagination Engine** - Add pagination loop to all three request templates
- [ ] **Phase 21: Stub Generation Integration** - Generate auto-paginating stubs for detected endpoints
- [ ] **Phase 22: Testing** - Unit and integration tests for pagination

## Phase Details

### Phase 19: Pagination Detection
**Goal**: Stub generator identifies paginated endpoints and classifies their pagination strategy
**Depends on**: Nothing (builds on existing schema parsing)
**Requirements**: PAG-01, PAG-02, PAG-03, PAG-04
**Success Criteria** (what must be TRUE):
  1. A regex-based registry of pagination parameter patterns exists and is configurable
  2. `openapi_to_spec()` output includes pagination metadata for endpoints that have pagination params
  3. Each paginated endpoint is classified as one of: `offset_limit`, `page_size`, `cursor`, or `path_pagination`
  4. All 5 known pagination patterns (AMOS offset/limit, AMOS keyset/cursor, ct pageNumber, cc offset/size, chemi page/size) are correctly detected
**Plans:** 1 plan

Plans:
- [x] 19-01-PLAN.md -- Add pagination registry, detection function, pipeline integration, and tests

### Phase 20: Auto-Pagination Engine
**Goal**: Request templates can automatically fetch all pages and combine results
**Depends on**: Phase 19
**Requirements**: PAG-05, PAG-06, PAG-07, PAG-08, PAG-09, PAG-10, PAG-11, PAG-12, PAG-13, PAG-17, PAG-18, PAG-19
**Success Criteria** (what must be TRUE):
  1. `generic_request()` with `paginate = TRUE` fetches all pages for offset/limit and page/size endpoints
  2. `generic_chemi_request()` with `paginate = TRUE` fetches all pages for chemi paginated endpoints
  3. `generic_cc_request()` with `paginate = TRUE` fetches all pages for CC search endpoints
  4. Cursor-based pagination follows cursor tokens until exhausted
  5. Path-based AMOS pagination increments offset path parameter correctly
  6. Combined results are a single tibble (tidy=TRUE) or single list (tidy=FALSE)
  7. Pagination stops after max_pages (default 100) or on empty/error response
  8. Verbose mode shows page progress via `cli`
**Plans**: TBD

### Phase 21: Stub Generation Integration
**Goal**: Generated stubs for paginated endpoints auto-paginate by default
**Depends on**: Phase 19, Phase 20
**Requirements**: PAG-14, PAG-15, PAG-16
**Success Criteria** (what must be TRUE):
  1. `build_function_stub()` produces stubs that call request templates with `paginate = TRUE` for paginated endpoints
  2. Generated stubs expose an `all_pages` parameter (default TRUE) to let users opt out
  3. Individual pagination params (page, offset, etc.) remain in the function signature for manual control
  4. Non-paginated endpoints are unaffected (no regression)
**Plans**: TBD

### Phase 22: Testing
**Goal**: Pagination detection and auto-pagination are verified by automated tests
**Depends on**: Phase 19, Phase 20, Phase 21
**Requirements**: PAG-20, PAG-21, PAG-22
**Success Criteria** (what must be TRUE):
  1. Unit tests verify regex detection catches all known pagination patterns from real schemas
  2. Unit tests verify each pagination strategy (offset, page, cursor, path) with mocked responses
  3. At least one integration test runs a paginated stub end-to-end with VCR cassettes
  4. All existing tests continue to pass (no regression)
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 19 -> 20 -> 21 -> 22

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 19. Pagination Detection | v2.0 | 1/1 | Complete | 2026-02-24 |
| 20. Auto-Pagination Engine | v2.0 | 0/TBD | Pending | - |
| 21. Stub Generation Integration | v2.0 | 0/TBD | Pending | - |
| 22. Testing | v2.0 | 0/TBD | Pending | - |
