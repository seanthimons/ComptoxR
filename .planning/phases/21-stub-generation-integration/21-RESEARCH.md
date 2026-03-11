# Phase 21: Stub Generation Integration - Research

**Researched:** 2026-02-24
**Domain:** R stub generation pipeline, pagination metadata integration, template call generation
**Confidence:** HIGH

## Summary

Phase 19 added pagination detection to `openapi_to_spec()`, which produces a spec tibble with `pagination_strategy` and `pagination_metadata` columns. Phase 20 added `paginate`, `max_pages`, and `pagination_strategy` parameters to all three request templates (`generic_request`, `generic_chemi_request`, `generic_cc_request`).

Phase 21 connects these: the stub generator (`build_function_stub()` in `dev/endpoint_eval/07_stub_generation.R`) must use the pagination metadata to generate stubs that:

1. **Call templates with `paginate = TRUE`** for paginated endpoints (PAG-14)
2. **Keep individual pagination params** (page, offset, limit) in function signature for manual control (PAG-15)
3. **Add `all_pages = TRUE` parameter** — when FALSE, uses manual pagination params (PAG-16)

**Current state:** The spec tibble already has pagination metadata (lines 1019-1020 in `07_stub_generation.R` show default values), but `build_function_stub()` doesn't receive or use it. The `pmap_chr` call at lines 1108-1144 doesn't include `pagination_strategy` or `pagination_metadata` in the parameter list.

**Primary recommendation:** Modify `render_endpoint_stubs()` to pass pagination metadata to `build_function_stub()`, then add logic to generate `all_pages` parameter and conditional `paginate` argument based on strategy.

## Standard Stack

### Core
No new libraries needed. This phase operates entirely within the existing stub generation pipeline:

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| glue | existing | Template string generation | Already used in stub generation |
| purrr | existing | List operations | Already used throughout pipeline |
| stringr | existing | String manipulation | Already used in pipeline |

## Architecture Patterns

### Pattern 1: Pagination Metadata Flow

**What:** Pagination metadata flows from schema parsing to stub generation in three stages.

**Current flow:**
```
openapi_to_spec()
  └─> detect_pagination()
      └─> Returns: list(strategy, registry_key, params, param_location, description)
          └─> Stored in spec tibble columns:
              - pagination_strategy (character)
              - pagination_metadata (list-column)

render_endpoint_stubs()
  └─> ensure_cols() defaults: pagination_strategy = "none", pagination_metadata = list(NULL)
  └─> pmap_chr() iteration
      └─> [CURRENT GAP: pagination columns NOT passed to build_function_stub]

build_function_stub()
  └─> [CURRENT GAP: doesn't receive pagination info]
  └─> Generates function code
```

**Required changes:**
```r
# In render_endpoint_stubs() pmap_chr call (line ~1108):
spec$text <- purrr::pmap_chr(
  list(
    # ... existing params ...
    pagination_strategy = spec$pagination_strategy,
    pagination_metadata = spec$pagination_metadata
  ),
  function(..., pagination_strategy, pagination_metadata) {
    build_function_stub(
      # ... existing args ...
      pagination_strategy = pagination_strategy,
      pagination_metadata = pagination_metadata
    )
  }
)

# In build_function_stub() signature (line ~153):
build_function_stub <- function(..., pagination_strategy = "none", pagination_metadata = NULL) {
  # ... existing code ...
}
```

### Pattern 2: all_pages Parameter Generation

**What:** For paginated endpoints, generate an `all_pages = TRUE` parameter that controls auto-pagination behavior.

**When to use:** When `pagination_strategy != "none"`.

**Function signature changes:**
```r
# Non-paginated endpoint (current):
chemi_amos_database <- function(query) { ... }

# Paginated endpoint (Phase 21):
chemi_amos_method_pagination <- function(limit, offset = 0, all_pages = TRUE) { ... }
```

**Logic:**
```r
# If pagination_strategy != "none":
if (!isTRUE(pagination_strategy == "none")) {
  # Add all_pages to fn_signature
  if (nzchar(fn_signature)) {
    fn_signature <- paste0(fn_signature, ", all_pages = TRUE")
  } else {
    fn_signature <- "all_pages = TRUE"
  }

  # Add @param docs
  param_docs <- paste0(
    param_docs,
    "#' @param all_pages Logical; if TRUE (default), fetches all pages automatically. ",
    "If FALSE, returns single page using manual pagination parameters.\n"
  )
}
```

### Pattern 3: Conditional paginate Argument

**What:** When `all_pages = TRUE`, pass `paginate = TRUE` to the template. When `FALSE`, pass individual pagination params.

**Implementation:**
```r
# In function body generation:
if (!isTRUE(pagination_strategy == "none")) {
  # Add conditional logic before template call
  paginate_code <- "  paginate_mode <- all_pages\n"

  # Modify template call
  paginate_param <- ",\n    paginate = paginate_mode"
  max_pages_param <- ",\n    max_pages = 100"  # Hardcoded default
  pagination_strategy_param <- paste0(',\n    pagination_strategy = "', pagination_strategy, '"')
} else {
  paginate_code <- ""
  paginate_param <- ""
  max_pages_param <- ""
  pagination_strategy_param <- ""
}
```

### Pattern 4: Strategy-Specific Stub Examples

**offset_limit (path params) - AMOS:**
```r
chemi_amos_method_pagination <- function(limit, offset = 0, all_pages = TRUE) {
  paginate_mode <- all_pages
  result <- generic_request(
    query = limit,
    endpoint = "amos/method_pagination/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(offset = offset),
    paginate = paginate_mode,
    max_pages = 100,
    pagination_strategy = "offset_limit"
  )
  return(result)
}
```

**page_number (query param) - CTX:**
```r
ct_hazard_toxref_observations <- function(studyType, pageNumber = 1, all_pages = TRUE) {
  paginate_mode <- all_pages
  result <- generic_request(
    query = studyType,
    endpoint = "hazard/toxref/observations/search/by-study-type/",
    method = "GET",
    batch_limit = 1,
    pageNumber = pageNumber,
    paginate = paginate_mode,
    max_pages = 100,
    pagination_strategy = "page_number"
  )
  return(result)
}
```

**page_size (query params) - Chemi Resolver:**
```r
chemi_resolver_classyfire <- function(query, page = 0, size = 1000, all_pages = TRUE) {
  paginate_mode <- all_pages
  result <- generic_request(
    endpoint = "resolver/classyfire",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    query = query,
    page = page,
    size = size,
    paginate = paginate_mode,
    max_pages = 100,
    pagination_strategy = "page_size"
  )
  return(result)
}
```

**offset_limit (body params) - Chemi Search:**
```r
chemi_search_exact <- function(query, offset = 0, limit = 100, all_pages = TRUE, ...) {
  paginate_mode <- all_pages

  # Build options from additional parameters
  options <- list(offset = offset, limit = limit)
  # ... additional option handling ...

  result <- generic_chemi_request(
    query = query,
    endpoint = "search",
    options = options,
    paginate = paginate_mode,
    max_pages = 100,
    pagination_strategy = "offset_limit"
  )
  return(result)
}
```

### Anti-Patterns to Avoid

- **Don't remove pagination params from signature:** Users should be able to manually control pagination even when `all_pages = FALSE`. Keep limit/offset/page/pageNumber in the signature.
- **Don't hardcode pagination strategy strings in multiple places:** Use the `pagination_strategy` value from metadata, not hardcoded strings.
- **Don't make `all_pages` required:** Default should be `TRUE` for convenience.

## Current Pagination Endpoint Count

Analysis of actual schemas shows exactly **10 paginated endpoints** in AMOS (5 offset_limit, 5 cursor), plus multiple CTX hazard/exposure endpoints with pageNumber, chemi-search, chemi-resolver, and commonchemistry endpoints.

**AMOS example (from chemi-amos-dev.json):**
- `/api/amos/analytical_qc_pagination/{limit}/{offset}`
- `/api/amos/fact_sheet_pagination/{limit}/{offset}`
- `/api/amos/method_pagination/{limit}/{offset}`
- `/api/amos/product_declaration_pagination/{limit}/{offset}`
- `/api/amos/safety_data_sheet_pagination/{limit}/{offset}`
- `/api/amos/analytical_qc_keyset_pagination/{limit}` + cursor query
- `/api/amos/fact_sheet_keyset_pagination/{limit}` + cursor query
- `/api/amos/method_keyset_pagination/{limit}` + cursor query
- `/api/amos/product_declaration_keyset_pagination/{limit}` + cursor query
- `/api/amos/safety_data_sheet_keyset_pagination/{limit}` + cursor query

**Currently generated stub (R/chemi_amos_method_pagination.R):**
```r
chemi_amos_method_pagination <- function(limit, offset = NULL) {
  result <- generic_request(
    query = limit,
    endpoint = "amos/method_pagination/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(offset = offset)
  )
  return(result)
}
```

**Phase 21 target:**
```r
chemi_amos_method_pagination <- function(limit, offset = 0, all_pages = TRUE) {
  paginate_mode <- all_pages
  result <- generic_request(
    query = limit,
    endpoint = "amos/method_pagination/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(offset = offset),
    paginate = paginate_mode,
    max_pages = 100,
    pagination_strategy = "offset_limit"
  )
  return(result)
}
```

## Implementation Changes

### File: dev/endpoint_eval/07_stub_generation.R

**Change 1: build_function_stub() signature (line ~153)**
```r
# Add parameters:
build_function_stub <- function(
  fn, endpoint, method, title, batch_limit, path_param_info,
  query_param_info, body_param_info, content_type, config,
  needs_resolver = FALSE, body_schema_type = "unknown",
  deprecated = FALSE, response_schema_type = "unknown",
  request_type = NULL,
  pagination_strategy = "none",      # NEW
  pagination_metadata = NULL         # NEW
) {
  # ... existing code ...
}
```

**Change 2: Add all_pages parameter to signature (after line ~349)**
```r
# After building fn_signature for each endpoint type, add:
if (!isTRUE(pagination_strategy == "none")) {
  # Determine default value for offset/page parameters
  # offset_limit strategies usually default offset to 0
  # page strategies usually default page to 0 or 1
  # (This logic would examine pagination_metadata$params)

  # Add all_pages to signature
  if (nzchar(fn_signature %||% "")) {
    fn_signature <- paste0(fn_signature, ", all_pages = TRUE")
  } else {
    fn_signature <- "all_pages = TRUE"
  }

  # Add @param doc
  all_pages_doc <- "#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.\n"
  param_docs <- paste0(param_docs, all_pages_doc)
}
```

**Change 3: Add pagination params to template call (multiple locations)**

For each template call pattern (lines 479, 540, 602, 705, 746, 774, 790, 804, 868, 886, 927, 944), add conditional pagination arguments when `pagination_strategy != "none"`.

Example for `generic_request()` call:
```r
# Build pagination params
pagination_params <- if (!isTRUE(pagination_strategy == "none")) {
  glue::glue('
    paginate = all_pages,
    max_pages = 100,
    pagination_strategy = "{pagination_strategy}"')
} else {
  ""
}

# Insert into template call (before closing parenthesis)
fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
  result <- generic_request(
    query = {primary_param},
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {batch_limit_code}{pagination_params}
  )
  return(result)
}}
')
```

**Change 4: render_endpoint_stubs() pmap_chr call (line ~1108)**
```r
spec$text <- purrr::pmap_chr(
  list(
    fn = spec$fn,
    endpoint = spec$endpoint,
    method = spec$method,
    title = spec$title,
    batch_limit = spec$batch_limit,
    path_param_info = spec$path_param_info,
    query_param_info = spec$query_param_info,
    body_param_info = spec$body_param_info,
    content_type = spec$content_type,
    needs_resolver = spec$needs_resolver,
    body_schema_type = spec$body_schema_type,
    deprecated = spec$deprecated,
    response_schema_type = spec$response_schema_type,
    request_type = spec$request_type,
    pagination_strategy = spec$pagination_strategy,      # NEW
    pagination_metadata = spec$pagination_metadata       # NEW
  ),
  function(fn, endpoint, method, title, batch_limit, path_param_info,
           query_param_info, body_param_info, content_type, needs_resolver,
           body_schema_type, deprecated, response_schema_type, request_type,
           pagination_strategy, pagination_metadata) {               # NEW
    build_function_stub(
      fn = fn,
      endpoint = endpoint,
      method = method,
      title = title,
      batch_limit = batch_limit,
      path_param_info = path_param_info,
      query_param_info = query_param_info,
      body_param_info = body_param_info,
      content_type = content_type %|NA|% "",
      config = config,
      needs_resolver = isTRUE(as.logical(needs_resolver %|NA|% FALSE)),
      body_schema_type = body_schema_type %|NA|% "unknown",
      deprecated = isTRUE(as.logical(deprecated %|NA|% FALSE)),
      response_schema_type = response_schema_type %|NA|% "unknown",
      request_type = request_type %|NA|% "",
      pagination_strategy = pagination_strategy %|NA|% "none",     # NEW
      pagination_metadata = pagination_metadata                    # NEW
    )
  }
)
```

## Non-Paginated Endpoint Impact

**Critical verification:** Endpoints with `pagination_strategy = "none"` (the vast majority) must generate identical stubs to current behavior.

The conditional logic `if (!isTRUE(pagination_strategy == "none"))` ensures:
- No `all_pages` parameter added to signature
- No `paginate`/`max_pages`/`pagination_strategy` arguments added to template call
- No behavior change for existing non-paginated stubs

**Test strategy:** Compare generated stubs for non-paginated endpoints before/after Phase 21 using snapshot tests.

## Common Pitfalls

### Pitfall 1: Default Values for Pagination Params
**What goes wrong:** Pagination params (offset, page, limit) need sensible defaults. offset_limit strategies default offset to 0, page_size strategies default page to 0.
**Why it happens:** Different strategies use different conventions.
**How to avoid:** Extract defaults from `pagination_metadata$params` or use strategy-specific defaults.
**Warning signs:** Generated stubs with `offset = NULL` instead of `offset = 0`.

### Pitfall 2: all_pages Position in Signature
**What goes wrong:** Placing `all_pages` before required params breaks the signature.
**Why it happens:** Default params must come after required params in R.
**How to avoid:** Always append `all_pages` to the END of `fn_signature`.
**Warning signs:** R CMD check errors about "parameter without default following parameter with default".

### Pitfall 3: Path Params vs Query Params in Pagination
**What goes wrong:** AMOS offset/limit are path params, but CTX pageNumber is a query param. The template call structure differs.
**Why it happens:** Different APIs use different parameter locations.
**How to avoid:** Check `pagination_metadata$param_location` to determine where to place pagination params in the call.
**Warning signs:** Generated stubs with `path_params = c(pageNumber = pageNumber)` for CTX endpoints (should be a direct named argument).

### Pitfall 4: Body-Based Pagination (Chemi Search)
**What goes wrong:** Chemi search pagination params are in the request body (via `options`), not path/query.
**Why it happens:** POST endpoints with JSON bodies.
**How to avoid:** For `generic_chemi_request()` calls with `pagination_strategy = "offset_limit"` AND `param_location = "body"`, pagination params go into `options` list, not as separate arguments.

### Pitfall 5: Inserting Params into Glue Templates
**What goes wrong:** The `glue::glue()` calls use string interpolation. Adding pagination params requires careful comma placement.
**Why it happens:** Template strings are finicky about commas and newlines.
**How to avoid:** Use conditional string building: `pagination_params <- if (...) {...} else {""}` and insert with proper comma/newline handling.

## Code Examples

### Example 1: all_pages Signature Addition
```r
# Non-paginated (before):
fn_signature <- "dtxsid"

# Paginated (after Phase 21):
if (!isTRUE(pagination_strategy == "none")) {
  fn_signature <- paste0(fn_signature, ", all_pages = TRUE")
}
# Result: "dtxsid, all_pages = TRUE"
```

### Example 2: Conditional Pagination Params in Template Call
```r
# Build conditional params
pagination_call_params <- if (!isTRUE(pagination_strategy == "none")) {
  paste0(
    ",\n    paginate = all_pages",
    ",\n    max_pages = 100",
    ',\n    pagination_strategy = "', pagination_strategy, '"'
  )
} else {
  ""
}

# Insert into glue template
fn_body <- glue::glue('
{fn} <- function({fn_signature}) {{
  result <- generic_request(
    query = {primary_param},
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = {batch_limit_code}{pagination_call_params}
  )
  return(result)
}}
')
```

### Example 3: Strategy-Specific Default Value Assignment
```r
# Determine default values for pagination params
if (!isTRUE(pagination_strategy == "none")) {
  # Extract param names from metadata
  pag_params <- pagination_metadata$params %||% character(0)

  # Assign defaults based on param names and strategy
  if ("offset" %in% pag_params) {
    # offset_limit strategy: default offset = 0
    # Modify fn_signature to add default
    fn_signature <- gsub("offset", "offset = 0", fn_signature)
  } else if ("page" %in% pag_params) {
    # page_size strategy: default page = 0
    fn_signature <- gsub("page", "page = 0", fn_signature)
  } else if ("pageNumber" %in% pag_params) {
    # page_number strategy: default pageNumber = 1
    fn_signature <- gsub("pageNumber", "pageNumber = 1", fn_signature)
  }
}
```

## Open Questions

1. **Should max_pages be configurable in the generated stub?**
   - What we know: Phase 20 added `max_pages` parameter to templates with default 100.
   - What's unclear: Whether generated stubs should expose this as a function parameter or hardcode it.
   - Recommendation: Hardcode `max_pages = 100` in generated stubs for simplicity. Advanced users can call the template directly if they need to override.

2. **Should paginate_mode variable be created or inline the expression?**
   - Option A: `paginate_mode <- all_pages` then `paginate = paginate_mode`
   - Option B: `paginate = all_pages` directly
   - Recommendation: Use variable for clarity and consistency with existing generated stub patterns.

3. **How to handle pagination params with no defaults in metadata?**
   - What we know: Pagination metadata from Phase 19 includes param names but not default values.
   - What's unclear: Whether we need to infer defaults or require metadata update.
   - Recommendation: Use strategy-based defaults (offset=0, page=0, pageNumber=1) as fallback. This is safe because these are standard conventions.

## Sources

### Primary (HIGH confidence)
- Direct reading of `dev/endpoint_eval/07_stub_generation.R` (stub generation logic)
- Direct reading of `dev/endpoint_eval/04_openapi_parser.R` (pagination detection)
- Direct reading of `R/z_generic_request.R` (template pagination params)
- Analysis of `.planning/phases/19-pagination-detection/19-RESEARCH.md` (detection metadata)
- Analysis of `.planning/phases/20-auto-pagination-engine/20-RESEARCH.md` (template parameters)
- Examination of `R/chemi_amos_method_pagination.R` (current generated stub)
- Code analysis showing spec tibble already has `pagination_strategy` and `pagination_metadata` columns
- Grep analysis confirming pagination params exist in templates but not used in stubs

## Metadata

**Confidence breakdown:**
- Integration points: HIGH - Exact line numbers and existing patterns identified
- Stub generation changes: HIGH - Clear pattern for conditional param addition
- Template call modification: HIGH - Templates already support pagination params
- Non-paginated endpoint safety: HIGH - Conditional logic ensures no impact

**Research date:** 2026-02-24
**Valid until:** 2026-06-24 (stable - internal pipeline, not external API dependency)
