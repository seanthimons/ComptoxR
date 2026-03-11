# Phase 4: JSON Body Default - Research

**Researched:** 2026-01-27
**Domain:** OpenAPI code generation, R HTTP clients (httr2), request body encoding
**Confidence:** HIGH

## Summary

This phase fixes a regression introduced in v1.1 where the fix for `/chemical/search/equal/` (raw text body) accidentally broke all other bulk POST endpoints. The issue is that `string_array` body types are being sent as newline-delimited text instead of JSON arrays, violating OpenAPI specs and causing API failures.

The research confirms that:
1. OpenAPI distinguishes between `type: string` (single string) and `type: array, items: {type: string}` (array of strings)
2. httr2 provides `req_body_json()` for JSON encoding and `req_body_raw()` for raw text
3. Only `/chemical/search/equal/` POST requires raw text (`body_type = "raw_text"`); all other endpoints expect JSON
4. The stub generator has two code paths: "raw text body" (special case) and "simple body" (generic), but the generic path incorrectly collapses arrays to newlines

**Primary recommendation:** Remove newline collapsing from `string_array` body type generation path, use `generic_request()` default JSON encoding for all bulk POST endpoints except `/chemical/search/equal/`.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| httr2 | Current R package | HTTP client for API requests | Modern successor to httr, designed for API wrappers |
| jsonlite | Current R package | JSON encoding/decoding | R standard for JSON handling, used by httr2 |
| OpenAPI 3.0 | Spec standard | API schema definition | Industry standard for REST API documentation |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| glue | Current R package | String interpolation for code generation | Stub template rendering |
| purrr | tidyverse | Functional programming utilities | Processing spec tibbles |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| httr2 | httr (original) | httr2 is modern, pipe-friendly, better error handling |
| generic_request() | Direct httr2 calls | Lose batching, debug mode, error handling infrastructure |

**Installation:**
```r
# Already in DESCRIPTION dependencies
install.packages(c("httr2", "jsonlite", "glue", "purrr"))
```

## Architecture Patterns

### Pattern 1: OpenAPI Body Schema Detection
**What:** Parse OpenAPI `requestBody.content.application/json.schema` to determine body type
**When to use:** During stub generation to select correct request encoding

**Example:**
```r
# From dev/endpoint_eval/04_openapi_parser.R lines 128-195
get_body_schema_type <- function(request_body, openapi_spec) {
  # Navigate: requestBody -> content -> application/json -> schema
  json_schema <- content[["application/json"]][["schema"]] %||% list()

  schema_type <- json_schema[["type"]]
  if (schema_type == "string") {
    return("string")          # Single string - raw text candidate
  } else if (schema_type == "array") {
    items <- json_schema[["items"]] %||% list()
    item_type <- items[["type"]] %||% ""
    if (item_type == "string") {
      return("string_array")  # Array of strings - JSON array
    }
  }
}
```

### Pattern 2: httr2 Request Body Encoding
**What:** Choose correct body encoding method based on API expectations
**When to use:** All POST/PUT/PATCH requests with body content

**Example:**
```r
# Source: httr2.r-lib.org/reference/req_body.html

# JSON encoding (default for structured data)
req %>% httr2::req_body_json(query_part, auto_unbox = FALSE)

# Raw text encoding (special case for text/plain content-type)
req %>% httr2::req_body_raw(body_text, type = "text/plain")
```

**Key distinction:**
- `req_body_json()`: Encodes R data structures to JSON, sets `Content-Type: application/json`
- `req_body_raw()`: Sends literal string, requires explicit content-type

### Pattern 3: Endpoint-Specific Body Type Detection
**What:** Detect special case endpoints that deviate from JSON standard
**When to use:** Stub generation before selecting encoding strategy

**Example:**
```r
# From dev/endpoint_eval/07_stub_generation.R line 372-376
is_raw_text_body <- (
  body_schema_type == "string" &&
  toupper(method) == "POST" &&
  wrapper_fn == "generic_request"
)
```

### Pattern 4: Generic Request Template
**What:** Centralized request handler with configurable body encoding
**When to use:** All standard CompTox API endpoints

**Current implementation (R/z_generic_request.R lines 144-156):**
```r
if (toupper(method) == "POST") {
  req <- req %>% httr2::req_method("POST")

  # Set request body based on body_type
  if (body_type == "raw_text") {
    # Send as newline-delimited plain text (e.g., /chemical/search/equal/)
    body_text <- paste(query_part, collapse = "\n")
    req <- req %>% httr2::req_body_raw(body_text, type = "text/plain")
  } else {
    # Default: Send as JSON array
    req <- req %>% httr2::req_body_json(query_part, auto_unbox = FALSE)
  }
}
```

### Anti-Patterns to Avoid

- **Collapsing JSON arrays to newlines:** Never use `paste(query, collapse = "\n")` for JSON endpoints
- **Hardcoding endpoint names in generic_request():** Special cases belong in stub generation, not request template
- **Treating all string_array as newline-delimited:** Only `/chemical/search/equal/` POST uses this format per API docs

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON encoding edge cases | Custom jsonlite calls | httr2::req_body_json() | Handles auto_unbox, null handling, content-type headers automatically |
| Request batching logic | Manual batch splitting | generic_request() batch_limit | Already handles progress bars, error aggregation, batch splitting |
| OpenAPI schema parsing | String matching on endpoints | get_body_schema_type() | Correctly resolves $refs, handles inline schemas, detects array item types |
| Raw text body special case | Adding endpoint checks to generic_request() | Stub generation detection | Keeps generic_request() clean, documents special cases at generation time |

**Key insight:** The CompTox API has exactly ONE endpoint (`/chemical/search/equal/` POST) requiring raw text body. All other bulk POST endpoints expect JSON arrays. Custom solutions add complexity without value.

## Common Pitfalls

### Pitfall 1: Confusing OpenAPI schema types with encoding
**What goes wrong:** Seeing `type: string` in requestBody and assuming it means newline-delimited text
**Why it happens:** The `/chemical/search/equal/` endpoint uses `type: string` AND requires EOL separation (from API docs), creating false pattern
**How to avoid:** Check both schema type AND endpoint-specific documentation. Default to JSON unless API docs explicitly require text/plain
**Warning signs:**
- Generated functions have `paste(query, collapse = "\n")` but endpoint doesn't mention EOL
- OpenAPI schema says `type: array` but generated code collapses to string

### Pitfall 2: Applying special case logic too broadly
**What goes wrong:** v1.1 fix added "simple body" path that collapses ALL string_array to newlines
**Why it happens:** Pattern matching on body_schema_type without checking endpoint identity
**How to avoid:** Special case detection MUST include endpoint path, not just schema type
**Warning signs:**
- Multiple unrelated endpoints using same code generation path
- Code comments say "for compatibility" without specifying which endpoint

### Pitfall 3: Not testing against live API after regeneration
**What goes wrong:** Regenerated stubs pass R CMD check but fail at runtime with API errors
**Why it happens:** Schema parsing can be correct but encoding wrong; tests without VCR cassettes may not catch it
**How to avoid:** Always test one regenerated function against live API before bulk regeneration
**Warning signs:**
- VCR cassettes not updated after stub regeneration
- Test suite passes but users report API failures

### Pitfall 4: Misunderstanding httr2 auto_unbox behavior
**What goes wrong:** Single-element arrays sent as scalars instead of arrays
**Why it happens:** `auto_unbox = TRUE` (jsonlite default) converts length-1 vectors to scalars
**How to avoid:** Always use `auto_unbox = FALSE` in req_body_json() for API arrays
**Warning signs:**
- API returns errors for single-item queries but works for multi-item
- JSON looks like `"DTXSID123"` instead of `["DTXSID123"]`

## Code Examples

Verified patterns from official sources and codebase:

### Correct JSON Array Body (POST bulk endpoints)
```r
# Source: R/z_generic_request.R (default path, no body_type specified)
# Used by: ct_chemical_detail_search_bulk, ct_hazard_skin_eye_search_bulk, etc.

req <- httr2::request(base_url) %>%
  httr2::req_method("POST") %>%
  httr2::req_body_json(query_part, auto_unbox = FALSE)

# Sends: ["DTXSID7020182", "DTXSID9020112"]
# Content-Type: application/json
```

### Correct Raw Text Body (special case)
```r
# Source: R/ct_chemical_search_equal.R
# Used ONLY by: ct_chemical_search_equal_bulk

result <- generic_request(
  query = query,
  endpoint = "chemical/search/equal/",
  method = "POST",
  batch_limit = as.numeric(Sys.getenv("batch_limit", "1000")),
  body_type = "raw_text"  # Triggers paste(collapse = "\n") in generic_request
)

# Sends: "DTXSID7020182\nDTXSID9020112"
# Content-Type: text/plain
```

### INCORRECT Pattern (current bug)
```r
# Source: R/ct_hazard_skin_eye_search.R line 14-16 (BROKEN)
# Generated by: simple_body path in 07_stub_generation.R line 457-474

ct_hazard_skin_eye_search_bulk <- function(query) {
  # ❌ WRONG: Collapses array to newlines for non-raw-text endpoint
  body_string <- paste(query, collapse = "\n")

  result <- generic_request(
    query = body_string,  # ❌ Sends string instead of array
    endpoint = "hazard/skin-eye/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )
}

# Should send: ["DTXSID1", "DTXSID2"]
# Actually sends: "DTXSID1\nDTXSID2" (wrong!)
```

### Correct Fix (use generic_request default)
```r
# Fixed version - remove collapsing, let generic_request handle encoding

ct_hazard_skin_eye_search_bulk <- function(query) {
  result <- generic_request(
    query = query,  # ✅ Pass array directly
    endpoint = "hazard/skin-eye/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
    # No body_type param = defaults to JSON encoding
  )
  return(result)
}
```

### Stub Generation Fix
```r
# Source: dev/endpoint_eval/07_stub_generation.R line 370-412
# BEFORE (bug): Two separate paths both collapse to newlines

# Path 1: Raw text body (correct for /chemical/search/equal/)
is_raw_text_body <- (
  body_schema_type == "string" &&
  toupper(method) == "POST" &&
  wrapper_fn == "generic_request"
)

# Path 2: Simple body (INCORRECT - collapses string_array to newlines)
is_simple_body <- body_schema_type %in% c("string", "string_array")

if (body_schema_type == "string_array") {
  # ❌ BUG: Generates paste(query, collapse = "\n")
  fn_body <- glue::glue('
{fn} <- function(query) {{
  body_string <- paste(query, collapse = "\\n")  # WRONG
  result <- generic_request(query = body_string, ...)
}}')
}

# AFTER (fix): Only collapse for raw_text endpoint
is_raw_text_body <- (
  body_schema_type == "string" &&
  toupper(method) == "POST" &&
  wrapper_fn == "generic_request" &&
  endpoint == "chemical/search/equal/"  # ✅ Endpoint-specific check
)

# For string_array, use default JSON encoding
if (body_schema_type == "string_array") {
  fn_body <- glue::glue('
{fn} <- function(query) {{
  result <- generic_request(
    query = query,  # ✅ Pass array, let generic_request encode as JSON
    endpoint = "{endpoint}",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  return(result)
}}')
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom httr2 code per endpoint | generic_request() template | v1.0 refactoring | Centralized batching, error handling, debug mode |
| Hardcoded batch limits | Sys.getenv("batch_limit") | v1.0 | Runtime configurability |
| No special case handling | body_type parameter in generic_request() | v1.1 | Supports raw text body endpoints |
| String body = newline collapse | String body = check endpoint first | v1.2 (this phase) | Only special case gets raw text |

**Deprecated/outdated:**
- **Standalone httr2 request code in stubs:** Replaced by generic_request() for consistency
- **is_simple_body path for string_array:** Incorrect assumption that arrays need newline collapsing
- **Body type detection without endpoint check:** Must verify endpoint path, not just schema type

## Open Questions

None - all technical questions resolved through codebase investigation and OpenAPI spec verification.

## Sources

### Primary (HIGH confidence)
- httr2 documentation: https://httr2.r-lib.org/reference/req_body.html (official docs, verified Feb 2024)
- OpenAPI 3.0 spec: https://swagger.io/docs/specification/describing-request-body/ (official spec)
- Codebase files:
  - `R/z_generic_request.R` lines 144-156 (body_type implementation)
  - `dev/endpoint_eval/07_stub_generation.R` lines 370-494 (stub generation paths)
  - `dev/endpoint_eval/04_openapi_parser.R` lines 128-195 (schema type detection)
  - `schema/ctx-chemical-prod.json` (OpenAPI schema validation)

### Secondary (MEDIUM confidence)
- Phase 3 implementation: `.planning/phases/03-raw-text-body/03-01-SUMMARY.md` (decision RAW-TEXT-01)
- Project state: `.planning/PROJECT.md` (v1.1 accomplishments, v1.2 requirements)

### Tertiary (LOW confidence)
None used.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - httr2, jsonlite, OpenAPI are established standards verified in codebase
- Architecture: HIGH - All patterns verified in existing code and official documentation
- Pitfalls: HIGH - Direct evidence from git history showing v1.1 regression

**Research date:** 2026-01-27
**Valid until:** 30 days (stable domain - R HTTP client patterns, OpenAPI 3.0 spec)

**Key findings verified:**
1. ✅ OpenAPI schema parsing logic confirmed in `04_openapi_parser.R`
2. ✅ httr2 body encoding methods verified in official docs
3. ✅ Current bug pattern confirmed in 38+ generated R files
4. ✅ generic_request() implementation supports both JSON and raw text
5. ✅ Only `/chemical/search/equal/` POST requires raw text per OpenAPI description field
