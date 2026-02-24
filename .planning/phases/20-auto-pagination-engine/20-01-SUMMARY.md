---
phase: 20-auto-pagination-engine
plan: 01
subsystem: generic-request-templates
tags: [pagination, httr2, iterative-requests]
dependency_graph:
  requires: [19-01]
  provides: [generic_request-pagination, generic_cc_request-pagination]
  affects: [all-paginated-endpoint-stubs]
tech_stack:
  added: []
  patterns: [httr2-req_perform_iterative, iterate_with_offset, iterate_with_cursor]
key_files:
  created: []
  modified:
    - R/z_generic_request.R
    - tests/testthat/test-generic_request.R
decisions:
  - Used httr2 built-in iteration (req_perform_iterative) instead of custom loop
  - Custom next_req callback for AMOS path-based offset since iterate_with_offset only handles query params
  - pipe operator used native |> in pagination code for consistency with modern R
metrics:
  duration: 4 min
  completed: 2026-02-24
  tasks: 3/3
  files_modified: 2
  tests_added: 8
---

# Phase 20 Plan 01: Auto-Pagination Engine Summary

Automatic pagination for generic_request() and generic_cc_request() using httr2 req_perform_iterative with 5 strategy implementations covering all EPA API pagination patterns.

## What Was Done

### Task 1: Add pagination to generic_request()
- Added `paginate`, `max_pages`, `pagination_strategy` parameters to function signature
- Added roxygen documentation for all three new parameters
- Implemented 5 pagination strategies as a new Section 5.5 between debug hook and execution:
  - **offset_limit (path)**: Custom next_req callback for AMOS path-based offset/limit; rebuilds URL path segments using httr2::url_parse/url_modify
  - **page_number**: iterate_with_offset("pageNumber", start=1) with empty-response completion check
  - **page_size**: iterate_with_offset("page", start=0) with Spring Boot resp_pages and resp_complete (last=TRUE)
  - **offset_limit (query)**: iterate_with_offset("offset", offset=size) with flexible record extraction
  - **cursor**: iterate_with_cursor("cursor") extracting cursor/nextCursor/next from response body
- All strategies use req_perform_iterative with on_error="return" and resps_successes filtering
- Progress bar tied to verbose flag via progress=run_verbose
- paginate=FALSE (default) bypasses entire section, preserving all existing behavior

### Task 2: Add pagination to generic_cc_request()
- Added `paginate`, `max_pages`, `pagination_strategy` parameters
- Implemented CC offset/size pagination via iterate_with_offset("offset") with resp_complete checking results count
- Extracts records from "results" field; handles string count with as.numeric()
- Same output formatting (tidy/list) as non-paginated path

### Task 3: Add pagination tests
- 8 new test cases covering all pagination scenarios:
  1. paginate=FALSE preserves existing behavior
  2. page_number fetches multiple pages (2 data + 1 empty = stop)
  3. page_size (Spring Boot) stops on last=TRUE
  4. max_pages limit respected (caps at 3 even with infinite data)
  5. Empty results return empty tibble with warning
  6. tidy=FALSE returns list
  7. Cursor pagination follows cursor tokens until NULL
  8. generic_cc_request offset/size pagination
- All tests use with_mocked_bindings on httr2::req_perform (called internally by req_perform_iterative)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed CC pagination test page size mismatch**
- **Found during:** Task 3
- **Issue:** Test mock returned 1 result per page with size=2, triggering premature resp_complete (1 < 2)
- **Fix:** Changed test to use size=1 so full pages return 1 result, matching the completion logic
- **Files modified:** tests/testthat/test-generic_request.R
- **Commit:** 95733dc

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 7bec9a4 | feat(20-01): add pagination to generic_request() |
| 2 | 5e51658 | feat(20-01): add pagination to generic_cc_request() |
| 3 | 95733dc | test(20-01): add pagination tests |

## Verification Results

- Package loads without errors
- generic_request() signature includes paginate/max_pages/pagination_strategy
- generic_cc_request() signature includes paginate/max_pages/pagination_strategy
- All 33 tests pass (5 existing + 8 new pagination + 20 assertion checks)
- paginate=FALSE default preserves all existing behavior
