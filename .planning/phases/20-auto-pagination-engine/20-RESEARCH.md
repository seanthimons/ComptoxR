# Phase 20: Auto-Pagination Engine - Research

**Researched:** 2026-02-24
**Domain:** HTTP pagination loops, R httr2 iteration helpers, EPA API response structures
**Confidence:** HIGH

## Summary

This phase adds automatic pagination to the three generic request templates (`generic_request`, `generic_chemi_request`, `generic_cc_request`) so that paginated endpoints fetch all pages and combine results transparently. Phase 19 added detection metadata; this phase uses it at runtime.

**Key discovery:** httr2 (v1.2.1, already installed) provides built-in pagination support via `req_perform_iterative()`, `iterate_with_offset()`, and `iterate_with_cursor()`. We should use these instead of rolling a custom loop.

## httr2 Iteration Infrastructure

### req_perform_iterative()

```r
req_perform_iterative(
  req,              # First request to perform
  next_req,         # Callback: function(resp, req) -> next request or NULL
  path = NULL,      # Optional: save bodies to disk
  max_reqs = 20,    # Max requests (use Inf for all)
  on_error = "stop", # "stop" or "return" (return collects successful responses)
  progress = TRUE   # Progress bar
)
# Returns: list of httr2_response objects
```

### iterate_with_offset()

```r
iterate_with_offset(
  param_name,           # Query parameter to increment (e.g., "page", "offset")
  start = 1,            # Starting value
  offset = 1,           # Increment per page (1 for page, page_size for offset)
  resp_pages = NULL,     # Callback: function(resp) -> total pages or NULL
  resp_complete = NULL   # Callback: function(resp) -> TRUE when done
)
```

Handles: page_number, page_size, offset_limit (query params).

### iterate_with_cursor()

```r
iterate_with_cursor(
  param_name,           # Query parameter for cursor
  resp_param_value      # Callback: function(resp) -> next cursor or NULL
)
```

Handles: cursor/keyset pagination.

### resps_data()

```r
resps_data(resps, resp_data)
# resp_data: function(resp) -> vector or data frame from one response
# Returns: combined vector/data frame across all responses (uses vctrs::vec_rbind)
```

### Custom next_req for non-standard patterns

For patterns that don't fit the helpers (body-based offset, path-based offset), write a custom `next_req` callback:

```r
next_req <- function(resp, req) {
  body <- resp_body_json(resp)
  if (body$offset + body$recordsCount >= body$totalRecordsCount) return(NULL)
  req |> req_body_json_modify(offset = body$offset + body$limit)
}
```

## Response Structures by API

### 1. AMOS Path-Based Offset/Limit
**Template:** `generic_request()` with `batch_limit = 1`, `path_params`
**Request:** `GET /amos/method_pagination/{limit}/{offset}`
**Response:** Plain JSON array of records. No pagination metadata.
**Exhaustion:** `length(results) < limit` or empty array.
**Current stub pattern:**
```r
generic_request(query = limit, endpoint = "amos/method_pagination/",
  method = "GET", batch_limit = 1, path_params = c(offset = offset))
```
**Challenge:** `limit` is the first path param (mapped to `query`), `offset` is in `path_params`. For auto-pagination, need custom `next_req` that rebuilds the URL with new offset path segment. `iterate_with_offset()` only works with query params, so this needs a custom callback.

### 2. CTX pageNumber Query
**Template:** `generic_request()` with `batch_limit = 1`, named query param
**Request:** `GET /hazard/toxref/observations/search/by-study-type/{studyType}?pageNumber=1`
**Response:** JSON array of records. No pagination metadata.
**Exhaustion:** Empty response or `length(results) == 0`.
**httr2 fit:** `iterate_with_offset("pageNumber", start = 1, resp_complete = \(resp) length(resp_body_json(resp)) == 0)`

### 3. Chemi Search Body Offset/Limit
**Template:** `generic_chemi_request()` with `options` containing offset/limit
**Request:** `POST /search` with body `{searchType, inputType, query, offset, limit, ...}`
**Response:** Object with `totalRecordsCount`, `recordsCount`, `records`, `offset`, `limit`.
**Exhaustion:** `offset + recordsCount >= totalRecordsCount` or `recordsCount == 0`.
**httr2 fit:** Custom `next_req` using `req_body_json_modify()` to increment offset in body.

### 4. Chemi Resolver Page/Size (Spring Boot Pageable)
**Template:** `generic_request()` with `batch_limit = 0`, query params
**Request:** `GET /resolver/classyfire?query=...&page=0&size=1000`
**Response:** Spring Boot Page: `{totalPages, totalElements, size, content, number, last, first, empty}`.
**Exhaustion:** `last == TRUE` or `number >= totalPages - 1`.
**httr2 fit:** `iterate_with_offset("page", start = 0, resp_pages = \(resp) resp_body_json(resp)$totalPages, resp_complete = \(resp) isTRUE(resp_body_json(resp)$last))`

### 5. Common Chemistry Offset/Size
**Template:** `generic_cc_request()` with query params
**Request:** `GET /search?q=...&offset=0&size=100`
**Response:** `{count: "N", results: [...]}`.
**Exhaustion:** `offset + length(results) >= as.numeric(count)` or `length(results) < size`.
**httr2 fit:** `iterate_with_offset("offset", start = 0, offset = size, resp_complete = \(resp) { body <- resp_body_json(resp); length(body$results) < size || length(body$results) == 0 })`

### 6. AMOS Cursor/Keyset
**Template:** `generic_request()` with `batch_limit = 1`, path + query
**Request:** `GET /amos/method_keyset_pagination/{limit}?cursor=...`
**Response:** Records array + cursor field (exact field name TBD — only in dev API).
**httr2 fit:** `iterate_with_cursor("cursor", \(resp) resp_body_json(resp)$cursor)`
**Note:** Only exists in dev AMOS API, not production. Low priority.

## Strategy-to-httr2 Mapping

| Strategy | httr2 Helper | Param | Notes |
|----------|-------------|-------|-------|
| `page_number` | `iterate_with_offset()` | "pageNumber", start=1 | resp_complete checks empty response |
| `page_size` | `iterate_with_offset()` | "page", start=0 | resp_pages + resp_complete from Spring Boot fields |
| `offset_limit` (query) | `iterate_with_offset()` | "offset", offset=size | resp_complete checks record count |
| `offset_limit` (path) | Custom `next_req` | Rebuilds URL | Path params not supported by helpers |
| `offset_limit` (body) | Custom `next_req` | `req_body_json_modify()` | Body params not supported by helpers |
| `cursor` | `iterate_with_cursor()` | "cursor" | resp_param_value extracts cursor |

## Architecture: How to Integrate

### Approach: Template-level `paginate` parameter

Each generic template gets `paginate = FALSE`, `max_pages = 100`, `pagination_strategy = NULL`.

When `paginate = TRUE`:
1. Build the first request (existing logic — reuse `req_list[[1]]`)
2. Construct the appropriate `next_req` callback based on `pagination_strategy`
3. Call `req_perform_iterative(req, next_req, max_reqs = max_pages, on_error = "return")`
4. Extract data from responses using strategy-specific `resp_data` function
5. Apply existing tidy conversion

This replaces the normal execution path (Section 6 in generic_request). When `paginate = FALSE`, everything works exactly as before.

### Record Extraction per Strategy

Each strategy needs a `resp_data` callback for `resps_data()`:

| Strategy | Extract Pattern |
|----------|----------------|
| page_number | `resp_body_json(resp)` (top-level array) |
| page_size | `resp_body_json(resp)$content` (Spring Boot content) |
| offset_limit (query) | `resp_body_json(resp)$results` (CC) or `resp_body_json(resp)` (AMOS) |
| offset_limit (body) | `resp_body_json(resp)$records` (Chemi Search) |
| cursor | `resp_body_json(resp)` or `resp_body_json(resp)$data` |

## File Plan

| File | Changes |
|------|---------|
| `R/z_generic_request.R` | Add `paginate`/`max_pages`/`pagination_strategy` to `generic_request()`, `generic_chemi_request()`, `generic_cc_request()`. Pagination branches using `req_perform_iterative()`. |
| `tests/testthat/test-generic_request.R` | Add pagination tests with mocked multi-page responses |

## Common Pitfalls

### Pitfall 1: iterate_with_offset only modifies QUERY params
Path-based offset (AMOS) and body-based offset (Chemi Search) need custom `next_req` callbacks that rebuild the URL or modify the body directly.

### Pitfall 2: resps_data() requires vctrs
The `resps_data()` function uses `vctrs::vec_rbind()`. Check that vctrs is available (it should be as a tidyverse dependency).

### Pitfall 3: max_reqs vs max_pages naming
httr2 uses `max_reqs` (number of requests including the first). Our API says `max_pages`. If user passes `max_pages = 100`, pass `max_reqs = 100` to httr2.

### Pitfall 4: on_error = "return" collects errors in the list
When using `on_error = "return"`, the returned list may contain error objects. Must filter with `resps_successes()` before extracting data.

### Pitfall 5: Progress bar conflicts
httr2's `progress` in `req_perform_iterative()` conflicts with `req_progress()`. Since we don't use `req_progress()`, this is fine. Use `progress = run_verbose` to match our verbose flag.

### Pitfall 6: String count fields
Common Chemistry returns `count` as a string, not integer. Always use `as.numeric()`.

## Sources

### Primary (HIGH confidence)
- httr2 1.2.1 documentation: `req_perform_iterative()`, `iterate_with_offset()`, `iterate_with_cursor()`, `resps_data()`
- Direct reading of `R/z_generic_request.R` (all 4 templates)
- Schema analysis from Phase 19 research
- Generated stub files examining current call patterns
- Existing test patterns (`tests/testthat/test-generic_request.R`)

## Metadata

**Confidence breakdown:**
- httr2 iteration API: HIGH (verified installed, docs read)
- Response structures: HIGH (from schema analysis)
- Architecture: HIGH (clear integration points)
- Strategy mapping: HIGH (5 patterns fully characterized)

**Research date:** 2026-02-24
**Valid until:** 2026-06-24
