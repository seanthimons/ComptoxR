# Requirements: ComptoxR v2.0 Paginated Requests

**Defined:** 2026-02-24
**Core Value:** Paginated API endpoints return all results transparently — users call a function once and get everything back.

## v2.0 Requirements

Requirements for automatic pagination support across all EPA API endpoints.

### Pagination Pattern Detection (stub generation)

- [x] **PAG-01**: Stub generator detects pagination parameters using regex patterns (e.g., `page`, `pageNumber`, `offset`, `limit`, `cursor`, `size`) from OpenAPI schemas
- [x] **PAG-02**: Detection patterns are configurable via a central registry (list/vector) so new patterns can be added without modifying detection logic
- [x] **PAG-03**: Detected pagination metadata (pattern type, param names, defaults) is stored in the endpoint spec and available to `build_function_stub()`
- [x] **PAG-04**: Stub generator classifies each paginated endpoint into a pagination strategy: `offset_limit`, `page_size`, `cursor`, or `path_pagination`

### Auto-Pagination in Request Templates

- [ ] **PAG-05**: `generic_request()` accepts a `paginate` parameter that triggers automatic fetching of all pages
- [x] **PAG-06**: `generic_chemi_request()` accepts a `paginate` parameter for cheminformatics paginated endpoints
- [ ] **PAG-07**: `generic_cc_request()` accepts a `paginate` parameter for CAS Common Chemistry paginated endpoints
- [x] **PAG-08**: Offset/limit pagination: automatically increments offset until response returns fewer results than the limit
- [ ] **PAG-09**: Page/size pagination: automatically increments page number until response returns fewer results than page size or an empty page
- [ ] **PAG-10**: Cursor-based pagination: follows cursor tokens from response until no next cursor is returned
- [ ] **PAG-11**: Path-based pagination (AMOS `/{limit}/{offset}`): auto-increments offset path parameter across requests
- [x] **PAG-12**: All pagination strategies combine results into a single tibble (tidy=TRUE) or single list (tidy=FALSE)
- [ ] **PAG-13**: Progress feedback via `cli` when verbose mode is enabled (e.g., "Fetching page 3...")

### Generated Stub Integration

- [ ] **PAG-14**: Generated stubs for paginated endpoints call their request template with `paginate = TRUE` by default
- [ ] **PAG-15**: Generated stubs retain individual pagination params (page, offset, etc.) so users can manually paginate if needed
- [ ] **PAG-16**: Generated stubs include `all_pages` parameter (default TRUE) — when FALSE, returns single page using the provided pagination params

### Safety and Limits

- [ ] **PAG-17**: Auto-pagination has a configurable maximum page count (default: 100) to prevent runaway loops
- [ ] **PAG-18**: Auto-pagination respects rate limits — uses sequential requests (not parallel) with configurable delay between pages
- [ ] **PAG-19**: Empty or error responses during pagination stop the loop gracefully and return results collected so far

### Testing

- [ ] **PAG-20**: Unit tests for pagination pattern detection regex against all known endpoint schemas
- [ ] **PAG-21**: Unit tests for each pagination strategy in `generic_request()` using mocked responses
- [ ] **PAG-22**: Integration test: generated stub for a paginated endpoint auto-paginates correctly with VCR cassettes

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Advanced Schema Handling (carried from v1.9)

- **ADV-01**: Content-type extraction from OpenAPI specs
- **ADV-02**: Primitive type detection for body schemas
- **ADV-03**: Nested array type handling
- **ADV-04**: GH Action alignment validation

## Out of Scope

| Feature | Reason |
|---------|--------|
| Parallel page fetching | Rate limits make sequential safer; parallel can be added later |
| Caching paginated results | Session caching is a separate concern |
| Retry logic per page | Covered by existing reliability (v1.9 REL-*) |
| Modifying existing hand-written functions | Only generated stubs and templates are in scope |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PAG-01 | Phase 19 | Complete |
| PAG-02 | Phase 19 | Complete |
| PAG-03 | Phase 19 | Complete |
| PAG-04 | Phase 19 | Complete |
| PAG-05 | Phase 20 | Pending |
| PAG-06 | Phase 20 | Complete |
| PAG-07 | Phase 20 | Pending |
| PAG-08 | Phase 20 | Complete |
| PAG-09 | Phase 20 | Pending |
| PAG-10 | Phase 20 | Pending |
| PAG-11 | Phase 20 | Pending |
| PAG-12 | Phase 20 | Complete |
| PAG-13 | Phase 20 | Pending |
| PAG-14 | Phase 21 | Pending |
| PAG-15 | Phase 21 | Pending |
| PAG-16 | Phase 21 | Pending |
| PAG-17 | Phase 20 | Pending |
| PAG-18 | Phase 20 | Pending |
| PAG-19 | Phase 20 | Pending |
| PAG-20 | Phase 22 | Pending |
| PAG-21 | Phase 22 | Pending |
| PAG-22 | Phase 22 | Pending |

**Coverage:**
- v2.0 requirements: 22 total
- Mapped to phases: 22/22 (100%)
- Unmapped: 0

---
*Requirements defined: 2026-02-24*
*Last updated: 2026-02-24 after Phase 20 Plan 02 completion*
