# Phase 19: Pagination Detection - Research

**Researched:** 2026-02-24
**Domain:** OpenAPI schema analysis, pagination pattern detection, R code generation pipeline
**Confidence:** HIGH

## Summary

This phase adds pagination detection to the existing stub generation pipeline. The pipeline currently parses OpenAPI schemas via `openapi_to_spec()` (in `04_openapi_parser.R`), which produces a tibble of endpoint specs consumed by `build_function_stub()` (in `07_stub_generation.R`). Pagination metadata must be detected during the parsing phase and attached to the spec tibble so downstream stub generation can use it.

Analysis of all 18 schema files containing pagination-related parameters reveals exactly 5 distinct pagination patterns across the EPA APIs. These patterns are reliably distinguishable using a combination of route path patterns and parameter name matching. The existing pipeline architecture cleanly supports adding a new metadata column (like the existing `needs_resolver`, `body_schema_type`, `request_type` columns) without structural changes.

**Primary recommendation:** Add a `detect_pagination()` function in `04_openapi_parser.R` that runs during `openapi_to_spec()`, classifies each endpoint's pagination strategy, and stores the result as new columns (`pagination_strategy`, `pagination_metadata`) in the spec tibble.

## Standard Stack

### Core
No new libraries needed. This phase operates entirely within the existing R pipeline using:

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| base R | 4.5.1 | Regex matching, list manipulation | Already in pipeline |
| stringr | existing | Pattern matching on routes/param names | Already used in parser |
| purrr | existing | List operations on param metadata | Already used in parser |
| tibble | existing | Spec tibble column additions | Already used in parser |

### Supporting
No additional libraries required.

## Architecture Patterns

### Where Pagination Detection Fits in the Pipeline

```
Schema JSON
    |
    v
openapi_to_spec()          <-- 04_openapi_parser.R
    |  [NEW: detect_pagination() called per-endpoint here]
    |  [Adds pagination_strategy + pagination_metadata columns]
    v
render_endpoint_stubs()    <-- 07_stub_generation.R
    |  [Can read pagination_strategy to adjust generated code]
    v
build_function_stub()      <-- 07_stub_generation.R
    |  [pagination_metadata available for future auto-pagination support]
    v
scaffold_files()           <-- 05_file_scaffold.R
```

### Pattern 1: Detection Function Design

**What:** A pure function that takes route, parameter names, parameter metadata, and body schema properties, then returns a classification.

**When to use:** Called once per endpoint during `openapi_to_spec()` iteration.

```r
# Detection function signature
detect_pagination <- function(route, path_params, query_params, body_params,
                               path_param_metadata, query_param_metadata,
                               body_param_metadata, registry = PAGINATION_REGISTRY) {
  # Returns list(strategy, params, metadata)
}
```

### Pattern 2: Central Registry for Detection Patterns

**What:** A named list constant (like existing `CHEMICAL_SCHEMA_PATTERNS` in `00_config.R`) that defines regex patterns for each pagination strategy. This satisfies PAG-02 (configurable via central registry).

**Where:** `00_config.R` alongside other constants.

```r
PAGINATION_REGISTRY <- list(
  offset_limit_path = list(
    strategy = "offset_limit",
    route_pattern = "_pagination/\\{[^}]+\\}/\\{[^}]+\\}$",
    param_names = c("limit", "offset"),
    param_location = "path",
    description = "AMOS-style offset/limit via path parameters"
  ),
  cursor_path = list(
    strategy = "cursor",
    route_pattern = "_keyset_pagination/\\{[^}]+\\}$",
    param_names = c("limit", "cursor"),
    param_location = c("path", "query"),
    description = "AMOS-style keyset/cursor pagination"
  ),
  page_number_query = list(
    strategy = "page_number",
    route_pattern = NULL,
    param_names = c("pageNumber"),
    param_location = "query",
    description = "CTX hazard/exposure pageNumber query parameter"
  ),
  offset_size_body = list(
    strategy = "offset_limit",
    route_pattern = NULL,
    param_names = c("offset", "limit"),
    param_location = "body",
    description = "Chemi search offset+limit in request body"
  ),
  offset_size_query = list(
    strategy = "offset_limit",
    route_pattern = NULL,
    param_names = c("offset", "size"),
    param_location = "query",
    description = "Common Chemistry offset+size query parameters"
  ),
  page_size_query = list(
    strategy = "page_size",
    route_pattern = NULL,
    param_names = c("page", "size"),
    param_location = "query",
    description = "Chemi resolver classyfire page+size query parameters"
  ),
  page_items_query = list(
    strategy = "page_size",
    route_pattern = NULL,
    param_names = c("page", "itemsPerPage"),
    param_location = "query",
    description = "Chemi resolver pubchem page+itemsPerPage query parameters"
  )
)
```

### Pattern 3: Spec Tibble Column Addition

**What:** Two new columns added to the spec tibble output of `openapi_to_spec()`:

| Column | Type | Content |
|--------|------|---------|
| `pagination_strategy` | character | One of: "offset_limit", "page_size", "page_number", "cursor", "none" |
| `pagination_metadata` | list-column | Named list with detected param names, locations, defaults, and registry entry used |

**Integration point:** In `openapi_to_spec()` at line ~506 (the `tibble::tibble()` call), add:

```r
# After existing fields like request_type, body_schema_full, etc.
pagination_info = list(detect_pagination(
  route, path_names, query_names, body_names,
  path_meta, query_meta, body_meta
)),
pagination_strategy = pagination_info[[1]]$strategy %||% "none"
```

And in `render_endpoint_stubs()` at line ~995, add default column:

```r
pagination_strategy = "none",
pagination_metadata = list(NULL)
```

### Pattern 4: Classification Heuristics

The detection algorithm should apply rules in priority order:

1. **Route-based detection first** (highest specificity, no false positives):
   - `_pagination/{limit}/{offset}` in route -> `offset_limit` (path-based)
   - `_keyset_pagination/{limit}` in route -> `cursor`

2. **Parameter-name detection second** (match against registry param_names):
   - Check query params for known pagination param name sets
   - Check body schema properties for known pagination param name sets
   - Require ALL param names in a registry entry to be present (AND logic, not OR)

3. **Return "none" if no match** (safe default)

### Anti-Patterns to Avoid

- **Don't detect on single param names:** A parameter named "limit" alone (without "offset" or in a pagination route) could be a regular batch size parameter. Always require the full set or a route pattern match.
- **Don't modify existing parameters:** The pagination params should still be extracted as normal function parameters. The `pagination_strategy` is metadata only -- it doesn't change how params are parsed, it provides information for future use.
- **Don't couple detection to stub generation in this phase:** PAG-03 says store metadata in the spec. Phase 19 does NOT need to change `build_function_stub()` behavior -- that's for a future phase.

## Discovered Pagination Patterns (from Schema Analysis)

### 1. Offset/Limit Path Params (AMOS)
**Schema files:** `chemi-amos-{dev,prod,staging}.json`
**Route pattern:** `*_pagination/{limit}/{offset}`
**Examples:**
- `/api/amos/analytical_qc_pagination/{limit}/{offset}`
- `/api/amos/fact_sheet_pagination/{limit}/{offset}`
- `/api/amos/method_pagination/{limit}/{offset}`
- `/api/amos/product_declaration_pagination/{limit}/{offset}`
- `/api/amos/safety_data_sheet_pagination/{limit}/{offset}`

**Parameters:** Both `limit` and `offset` are path params (required, integer).

### 2. Cursor/Keyset Path+Query (AMOS)
**Schema files:** `chemi-amos-{dev,prod,staging}.json`
**Route pattern:** `*_keyset_pagination/{limit}`
**Examples:**
- `/api/amos/analytical_qc_keyset_pagination/{limit}`
- `/api/amos/fact_sheet_keyset_pagination/{limit}`
- `/api/amos/method_keyset_pagination/{limit}`
- `/api/amos/product_declaration_keyset_pagination/{limit}`
- `/api/amos/safety_data_sheet_keyset_pagination/{limit}`

**Parameters:** `limit` is path param (required, integer), `cursor` is query param (optional, string).

### 3. pageNumber Query Param (CTX Hazard + Exposure)
**Schema files:** `ctx-hazard-{dev,prod,staging}.json`, `ctx-exposure-{dev,prod,staging}.json`
**Route pattern:** No distinguishing route pattern
**Examples:**
- `/hazard/toxref/observations/search/by-study-type/{studyType}` + `pageNumber` query
- `/hazard/toxref/effects/search/by-study-type/{studyType}` + `pageNumber` query
- `/hazard/toxref/data/search/by-study-type/{studyType}` + `pageNumber` query
- `/exposure/mmdb/single-sample/by-medium` + `pageNumber` query
- `/exposure/mmdb/aggregate/by-medium` + `pageNumber` query

**Parameters:** `pageNumber` is query param (optional, integer, default: 1). No explicit page size param -- server controls page size.

### 4. offset+limit/size in Body (Chemi Search)
**Schema files:** `chemi-search-{dev,prod,staging}.json`
**Route pattern:** `/api/search` (POST endpoints)
**Body schema properties:** `offset` (integer) and `limit` (integer) in `SearchRequest` schema, alongside other search params (`query`, `smiles`, `sortBy`, `sortDirection`).

### 5. page+size Query Params (Chemi Resolver)
**Schema files:** `chemi-resolver-{dev,prod,staging}.json`
**Examples:**
- `/api/resolver/classyfire` (GET) with `page` + `size` query params (optional, defaults: page=0, size=1000)
- `/api/resolver/getpubchemlist` (POST) with `page` + `itemsPerPage` query params (required)

### 6. offset+size Query Params (Common Chemistry)
**Schema files:** `commonchemistry-prod.json`
**Route:** `/search` (GET) with `q` + `offset` + `size` query params (all typed as string in this Swagger 2.0 schema).

## Strategy Classification Summary

| Strategy | Distinguishing Feature | Endpoints |
|----------|----------------------|-----------|
| `offset_limit` | Route contains `_pagination/{x}/{y}` OR body/query has offset+limit/size pair | AMOS pagination, chemi-search, commonchemistry |
| `cursor` | Route contains `_keyset_pagination` AND has `cursor` query param | AMOS keyset |
| `page_number` | Has `pageNumber` query param (no size param) | ctx-hazard toxref, ctx-exposure mmdb |
| `page_size` | Has `page`+`size` or `page`+`itemsPerPage` query param pair | chemi-resolver classyfire, chemi-resolver pubchem |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Regex pattern matching | Custom string parsing | `stringr::str_detect()` with registry patterns | Already used throughout pipeline, handles edge cases |
| Parameter name matching | Hardcoded if-else chains | Registry lookup with `all(names %in% params)` | Configurable, extensible, testable |

## Common Pitfalls

### Pitfall 1: False Positives from Single Parameter Names
**What goes wrong:** Matching on just "limit" or "offset" alone would flag non-paginated endpoints that happen to use these common parameter names for other purposes (e.g., `batch_limit` in generic_request).
**Why it happens:** These are common parameter names in APIs.
**How to avoid:** Always require the FULL set of parameter names from a registry entry, or a route pattern match.
**Warning signs:** Endpoints flagged as paginated that have only 1 of the expected pagination params.

### Pitfall 2: Body vs Query Parameter Location Confusion
**What goes wrong:** The chemi-search `offset`/`limit` params are in the request body schema, not query params. Detection must check ALL three locations (path, query, body).
**Why it happens:** Different APIs use different conventions for the same logical concept.
**How to avoid:** The registry entry specifies `param_location`, and detection checks the correct parameter set for each location.
**Warning signs:** Search endpoints not being detected as paginated.

### Pitfall 3: Swagger 2.0 vs OpenAPI 3.0 Schema Differences
**What goes wrong:** The AMOS schema is Swagger 2.0 (params defined differently), while CTX schemas are OpenAPI 3.0.
**Why it happens:** EPA APIs use different schema versions.
**How to avoid:** The detection function receives already-parsed parameter names (extracted by `openapi_to_spec()` which already handles both versions). Work with the normalized output, not raw schemas.
**Warning signs:** AMOS endpoints not being detected.

### Pitfall 4: Confusing "none" Strategy with Missing Detection
**What goes wrong:** Most endpoints (hundreds) have NO pagination. The detection must gracefully return "none" for these without generating warnings or noise.
**Why it happens:** Pagination is the exception, not the rule.
**How to avoid:** Default to "none". Only classify when a registry pattern positively matches.

## Code Examples

### Detection Function Implementation Pattern

```r
# Source: Project-specific design based on schema analysis
detect_pagination <- function(route, path_params, query_params, body_params,
                               path_param_metadata = list(),
                               query_param_metadata = list(),
                               body_param_metadata = list(),
                               registry = PAGINATION_REGISTRY) {
  # Split param strings to vectors
  path_vec <- if (nzchar(path_params %||% "")) strsplit(path_params, ",")[[1]] else character(0)
  query_vec <- if (nzchar(query_params %||% "")) strsplit(query_params, ",")[[1]] else character(0)
  body_vec <- if (nzchar(body_params %||% "")) strsplit(body_params, ",")[[1]] else character(0)
  path_vec <- trimws(path_vec)
  query_vec <- trimws(query_vec)
  body_vec <- trimws(body_vec)

  for (entry_name in names(registry)) {
    entry <- registry[[entry_name]]

    # Check route pattern first (if specified)
    if (!is.null(entry$route_pattern)) {
      if (!stringr::str_detect(route, entry$route_pattern)) next
    }

    # Check parameter names against specified location(s)
    required_names <- entry$param_names
    locations <- entry$param_location

    matched <- FALSE
    if ("path" %in% locations && all(required_names[required_names != "cursor"] %in% path_vec)) {
      # For cursor strategy, cursor is in query, limit is in path
      if (entry$strategy == "cursor") {
        matched <- "cursor" %in% query_vec && "limit" %in% path_vec
      } else {
        matched <- all(required_names %in% path_vec)
      }
    }
    if (!matched && "query" %in% locations && all(required_names %in% query_vec)) {
      matched <- TRUE
    }
    if (!matched && "body" %in% locations && all(required_names %in% body_vec)) {
      matched <- TRUE
    }

    if (matched) {
      return(list(
        strategy = entry$strategy,
        registry_key = entry_name,
        params = required_names,
        description = entry$description
      ))
    }
  }

  # No match
  list(strategy = "none", registry_key = NA_character_,
       params = character(0), description = "No pagination detected")
}
```

### Integration into openapi_to_spec()

```r
# Inside the purrr::map_dfr callback in openapi_to_spec(), after existing fields:

# Detect pagination strategy
pagination_info <- detect_pagination(
  route = route,
  path_params = if (length(path_names) > 0) paste(path_names, collapse = ",") else "",
  query_params = if (length(query_names) > 0) paste(query_names, collapse = ",") else "",
  body_params = if (length(body_names) > 0) paste(body_names, collapse = ",") else "",
  path_param_metadata = path_meta,
  query_param_metadata = query_meta,
  body_param_metadata = body_meta
)

# Add to tibble output:
tibble::tibble(
  # ... existing columns ...
  pagination_strategy = pagination_info$strategy,
  pagination_metadata = list(pagination_info)
)
```

### Column Default in render_endpoint_stubs()

```r
# In ensure_cols() call within render_endpoint_stubs():
spec <- ensure_cols(spec, list(
  # ... existing defaults ...
  pagination_strategy = "none",
  pagination_metadata = list(NULL)
))
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No pagination awareness | Pagination params treated as regular params | Current state | Generated stubs have limit/offset/page as normal function args |
| N/A | Pagination detection + metadata annotation | Phase 19 | Stubs will carry pagination strategy info for future auto-pagination |

## Open Questions

1. **Should detection order in the registry matter?**
   - What we know: Route-based patterns (AMOS) are more specific than param-name patterns. If we check route patterns first, we avoid false positives.
   - What's unclear: Whether any endpoint could match multiple registry entries.
   - Recommendation: Order registry entries from most specific (route pattern) to least specific (param name only). First match wins. This is safe because the AMOS route patterns are highly distinctive.

2. **Should the `page_number` strategy (single pageNumber param, no size) be separate from `page_size`?**
   - What we know: CTX hazard/exposure endpoints have `pageNumber` alone (server controls page size). Chemi resolver endpoints have `page` + `size` (client controls both).
   - What's unclear: Whether downstream consumers need to distinguish these.
   - Recommendation: Keep them separate. `page_number` = server-controlled page size, `page_size` = client-controlled. This matches the requirement PAG-04 which lists 4 strategies. Map `page_number` under a distinct strategy name rather than collapsing with `page_size`.

3. **Should `offset_limit` body params (chemi-search) be treated the same as query/path `offset_limit`?**
   - What we know: The mechanism differs (body vs path/query) but the pagination concept is the same.
   - Recommendation: Use the same `offset_limit` strategy but record `param_location = "body"` in metadata so downstream can handle the implementation difference.

## Sources

### Primary (HIGH confidence)
- Direct analysis of 18 schema files in `schema/` directory containing pagination parameters
- Source code analysis of `dev/endpoint_eval/04_openapi_parser.R` (openapi_to_spec)
- Source code analysis of `dev/endpoint_eval/07_stub_generation.R` (build_function_stub, render_endpoint_stubs)
- Source code analysis of `dev/endpoint_eval/00_config.R` (existing constants pattern)
- Source code analysis of `dev/endpoint_eval/06_param_parsing.R` (parameter parsing)
- Source code analysis of `dev/endpoint_eval/01_schema_resolution.R` (schema resolution)
- Existing generated stubs in `R/chemi_amos_*_pagination.R` (current pagination handling)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - No new dependencies, pure analysis of existing codebase
- Architecture: HIGH - Clear integration points identified in actual source code, follows existing patterns (CHEMICAL_SCHEMA_PATTERNS, body_schema_type, request_type)
- Pitfalls: HIGH - Derived from actual schema analysis showing concrete edge cases
- Detection patterns: HIGH - Exhaustive analysis of all 18 schema files with pagination params

**Research date:** 2026-02-24
**Valid until:** 2026-06-24 (stable - internal pipeline, not external dependency)
