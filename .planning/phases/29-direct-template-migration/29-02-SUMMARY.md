---
phase: 29-direct-template-migration
plan: 02
subsystem: api-wrappers
tags:
  - migration
  - httr2-removal
  - server-switching
  - generic-request
dependency_graph:
  requires:
    - generic_request template (R/z_generic_request.R)
    - ctx_server for server switching (R/zzz.R)
  provides:
    - ct_related using generic_request (zero raw httr2 in package)
  affects:
    - All future ct_* functions (pattern established for server switching)
tech_stack:
  added: []
  patterns:
    - "batch_limit=0 with named parameters for query-string-based GET endpoints"
    - "on.exit for guaranteed server cleanup"
    - "Manual purrr::map loop when generic_request batching doesn't fit endpoint"
key_files:
  created: []
  modified:
    - R/ct_related.R (replaced httr2 with generic_request, guaranteed cleanup)
    - tests/testthat/test-ct_related.R (added server cleanup and validation tests)
    - NEWS.md (documented migration)
decisions:
  - title: "Use batch_limit=0 instead of batch_limit=1"
    context: "ct_related endpoint uses query parameter (?id=DTXSID) not path-based routing"
    rationale: "generic_request with batch_limit=1 appends query to path; batch_limit=0 treats endpoint as static and passes named args as query parameters"
    alternatives: ["Custom httr2 code (rejected - defeats migration purpose)", "Modify generic_request to support per-item query params (deferred - edge case)"]
    impact: "Established pattern for similar query-string-based endpoints"
  - title: "Manual loop instead of generic_request batching"
    context: "Endpoint doesn't support batching, needs per-DTXSID query parameter"
    rationale: "generic_request batching assumes homogeneous endpoint (single batch query or path-based iteration); ct_related needs heterogeneous per-item query params"
    alternatives: ["Force batching with custom endpoint (rejected - API doesn't support it)"]
    impact: "Slightly less concise than batch_limit=1 pattern, but matches endpoint behavior"
metrics:
  duration_minutes: 3
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 3
  tests_added: 4
  tests_passing: 7
  commits: 2
  lines_added: 72
  lines_removed: 104
  completed_date: "2026-03-11"
---

# Phase 29 Plan 02: ct_related Migration Summary

**One-liner:** Migrated ct_related from raw httr2 to generic_request with guaranteed server cleanup, eliminating all hand-written httr2 code from the package.

## What Was Built

Migrated the final hand-written httr2 function (`ct_related`) to use the generic_request() template. The function queries a non-standard endpoint (server 9 / dashboard scraping) that requires server switching with guaranteed cleanup. This completes Phase 29's goal of removing all raw httr2 code from the package.

**Key deliverables:**
- ct_related.R uses generic_request with batch_limit=0 pattern for query-string parameters
- Server cleanup guaranteed via on.exit (prevents URL leak on error)
- Error handling for empty API responses (edge case fix)
- Comprehensive test coverage for validation and cleanup behavior
- NEWS.md documents migration

## How It Works

### Implementation Pattern

**Challenge:** The related-substances endpoint uses a query parameter pattern (`?id=DTXSID`) rather than path-based routing, which doesn't fit generic_request's standard batch_limit=1 pattern (which appends query to path).

**Solution:**
```r
# Use batch_limit=0 (static endpoint) with manual loop
results <- purrr::map(
  query,
  function(dtxsid) {
    generic_request(
      query = NULL,
      endpoint = "related-substances/search/by-dtxsid",
      method = "GET",
      batch_limit = 0,  # Static endpoint - named args become query params
      auth = FALSE,
      tidy = FALSE,
      id = dtxsid  # Named parameter becomes ?id=DTXSID query parameter
    )
  },
  .progress = TRUE
)
```

### Server Switching with Guaranteed Cleanup

**Original approach (risky):**
```r
ctx_server(9)
# ... API call ...
ctx_server(1)  # Could be skipped if error occurs
```

**New approach (guaranteed):**
```r
old_server <- Sys.getenv("ctx_burl")
ctx_server(9)
on.exit(Sys.setenv(ctx_burl = old_server), add = TRUE)
# ... API call ... (cleanup executes even on error)
```

### Post-Processing Pipeline

Preserved original behavior exactly:
1. Extract "data" field from each response
2. Keep only "dtxsid" and "relationship" columns
3. Bind rows with query ID as a column
4. Rename dtxsid → child
5. Filter out parent compound (child != query)
6. If inclusive mode: filter to only compounds in original query set

## Deviations from Plan

### Auto-fixed Issues

**Rule 1 - Bug: Empty response error handling**
- **Found during:** Task 2 test execution
- **Issue:** When API returns empty or error response, no dtxsid column exists, causing rename failure
- **Fix:** Added early return for empty results before rename operation
- **Files modified:** R/ct_related.R (lines 78-81)
- **Commit:** abc68c5

No other deviations - plan executed as written.

## Testing

**Test results:**
- All 7 tests passing
- New tests added:
  1. Server cleanup verification (confirms URL restored after execution)
  2. Empty query validation
  3. Inclusive mode validation with single query
  4. Server cleanup on error (existing cassette reused)
- Existing VCR cassettes work unchanged (identical API behavior)

**Coverage:**
- Single DTXSID query (cassette: ct_related_single)
- Multi-DTXSID query (cassette: ct_related_example)
- Invalid DTXSID handling (cassette: ct_related_error)
- Server state restoration
- Input validation (empty query, inclusive=TRUE with single item)

## Files Changed

**Modified:**
- `R/ct_related.R` — Replaced raw httr2 with generic_request, added on.exit cleanup
- `tests/testthat/test-ct_related.R` — Added 4 new validation tests
- `NEWS.md` — Documented migration under Phase 29 Plan 02

**No files created** — Migration replaced existing implementation.

## Integration Points

**Upstream dependencies:**
- `R/z_generic_request.R` — batch_limit=0 pattern with named query parameters
- `R/zzz.R` — ctx_server() for server switching

**Downstream impact:**
- Zero raw httr2 code remaining in package
- Established pattern for query-string-based endpoints (not path-based)
- Proven on.exit cleanup pattern for server switching

## Known Limitations

1. **Endpoint stability:** Server 9 is a dashboard scraping endpoint, not an official API. The lifecycle::questioning badge remains appropriate.
2. **No batching support:** Endpoint requires per-DTXSID query, can't be optimized via batching.
3. **Manual loop:** Slightly more verbose than batch_limit=1 pattern, but matches endpoint behavior correctly.

## What's Next

**Phase 29 status:** Plan 02 complete. ct_properties and .prop_ids already deleted in Plan 01. Phase complete.

**Remaining v2.2 work:**
- Phase 30: Build quality validation (final checks, R CMD check green)

## Self-Check: PASSED

**Created files:** None (migration only) ✓

**Commits exist:**
```bash
$ git log --oneline -5
a313fad feat(29-01): delete ct_properties and .prop_ids, update tests and NEWS
abc68c5 feat(29-02): migrate ct_related to generic_request, update tests ✓
b5aeddb feat(29-01): add property coerce hook and update stubs
4da96fc feat(29-02): add ct_related_EXP using generic_request ✓
33da222 docs(29): create phase plan for direct template migration
```

**Tests pass:**
```bash
$ devtools::test_file("tests/testthat/test-ct_related.R")
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ] ✓
```

**No raw httr2 code:**
```bash
$ grep -r "httr2::" R/ct_related.R
(no matches) ✓
```

All verification criteria met.
