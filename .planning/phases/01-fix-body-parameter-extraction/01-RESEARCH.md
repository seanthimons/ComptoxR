# Phase 1: Fix Body Parameter Extraction - Research

**Researched:** 2026-01-26
**Domain:** R code generation from OpenAPI specifications
**Confidence:** HIGH

## Summary

This research investigates how to modify the ComptoxR stub generation pipeline to correctly extract and handle simple body parameter schemas (string and array-of-strings) from OpenAPI specifications. The current implementation treats POST request bodies as opaque schemas requiring object extraction, missing simple scalar types that should be treated as query-like parameters in the generated R function signatures.

The bug occurs because `extract_body_properties()` (in `01_schema_resolution.R`) only handles object and array-of-objects schemas, returning empty metadata for simple types. This causes `build_function_stub()` (in `07_stub_generation.R`) to generate functions without the primary parameter in their signature.

**Primary recommendation:** Extend `extract_body_properties()` to detect simple body schema types (string, array-of-strings) and return structured metadata indicating these should be treated as the primary `query` parameter, not as request body properties.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| httr2 | 1.0.0+ | HTTP client for R | Modern replacement for httr, used by generic_request() |
| jsonlite | Latest | JSON parsing/generation | Standard R JSON library, used for OpenAPI schema parsing |
| purrr | Latest | Functional programming | Part of tidyverse, used throughout stub generation |
| glue | Latest | String interpolation | Used in build_function_stub() for code generation |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| roxygen2 | Latest | Documentation generation | Automatically generates .Rd files from #' comments |
| devtools | Latest | Development workflow | Testing generated code with document() and check() |
| stringr | Latest | String manipulation | Pattern matching and cleaning in parsers |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| httr2 | httr | httr2 has better error handling and pipe-friendly API |
| jsonlite | rjson | jsonlite is more widely adopted and handles edge cases better |
| glue | paste0/sprintf | glue provides clearer, more maintainable string templates |

**Installation:**
```bash
# Already in DESCRIPTION, no new dependencies needed
```

## Architecture Patterns

### Recommended Project Structure
```
dev/endpoint_eval/
├── 01_schema_resolution.R       # Schema parsing and reference resolution
├── 04_openapi_parser.R          # Main OpenAPI spec parsing
├── 06_param_parsing.R           # Function parameter generation
└── 07_stub_generation.R         # Final code generation
```

### Pattern 1: Schema Type Detection and Metadata Flow

**What:** OpenAPI schema parsing flows through multiple stages, each extracting and passing metadata to the next stage.

**When to use:** When generating code from API specifications where parameter metadata (type, description, examples) needs to be preserved through the pipeline.

**Example:**
```r
# Stage 1: Extract body properties with type classification
# Source: dev/endpoint_eval/01_schema_resolution.R:135-220
extract_body_properties <- function(request_body, components) {
  # Navigate to schema
  json_schema <- content[["application/json"]][["schema"]]

  # Resolve references
  if (!is.null(json_schema[["$ref"]])) {
    json_schema <- resolve_schema_ref(json_schema[["$ref"]], components)
  }

  # Classify schema type
  type <- json_schema[["type"]]

  if (type == "string") {
    # MISSING: Simple string handling
    return(list(type = "string", properties = list()))
  } else if (type == "array") {
    items <- json_schema[["items"]]
    if (items[["type"]] == "string") {
      # MISSING: String array handling
      return(list(type = "string_array", properties = list()))
    }
  }
  # ... object handling
}

# Stage 2: Convert metadata to function parameters
# Source: dev/endpoint_eval/06_param_parsing.R:61-236
parse_function_params <- function(params_str, metadata = list()) {
  # Build signature from metadata
  fn_signature <- paste(required_params, collapse = ", ")

  # Generate @param docs from metadata
  for (p in param_vec) {
    entry <- metadata[[p]]
    desc <- entry$description %||% ""
    doc_lines <- c(doc_lines, paste0("#' @param ", p, " ", desc))
  }

  return(list(
    fn_signature = fn_signature,
    param_docs = param_docs,
    primary_param = primary_param
  ))
}

# Stage 3: Generate function stub
# Source: dev/endpoint_eval/07_stub_generation.R:31-678
build_function_stub <- function(..., body_param_info) {
  if (isTRUE(is_body_only)) {
    primary_param <- body_param_info$primary_param %||% "data"
    fn_signature <- body_param_info$fn_signature
    param_docs <- body_param_info$param_docs
  }
  # ... generate roxygen + function body
}
```

### Pattern 2: Request Type Classification

**What:** OpenAPI endpoints are classified into request types to determine parameter handling strategy.

**When to use:** When different HTTP methods and parameter locations require different code generation templates.

**Current classification (source: dev/endpoint_eval/04_openapi_parser.R:471-477):**
```r
request_type = if (method %in% c("POST", "PUT", "PATCH") && has_body) {
  "json"                    # POST with request body
} else if (length(path_names) > 0) {
  "path"                    # GET with path parameters
} else {
  "query_only"              # GET without path parameters
}
```

**Enhancement needed:**
```r
# Detect simple body types that should act like query params
request_type = if (method %in% c("POST", "PUT", "PATCH") && has_body) {
  if (body_props$type %in% c("string", "string_array")) {
    "simple_body"  # NEW: Simple body treated as query-like
  } else {
    "json"         # Complex object body
  }
} else if (length(path_names) > 0) {
  "path"
} else {
  "query_only"
}
```

### Pattern 3: Parameter Metadata Structure

**What:** Standardized list structure for parameter metadata that flows through the pipeline.

**When to use:** Whenever extracting parameter information from OpenAPI schemas.

**Structure (source: dev/endpoint_eval/01_schema_resolution.R:260-269):**
```r
metadata <- list(
  name = prop_name,
  type = prop[["type"]] %||% NA,
  format = prop[["format"]] %||% NA,
  description = prop[["description"]] %||% "",
  enum = prop[["enum"]] %||% NULL,
  default = prop[["default"]] %||% NA,
  required = prop_name %in% required_fields,
  example = prop[["example"]] %||% prop[["default"]] %||% NA
)
```

**Usage pattern:**
```r
# Extract metadata
body_meta <- extract_body_properties(request_body, components)

# Pass to parser
body_param_info <- parse_function_params(
  body_params_str,
  metadata = body_meta$properties
)

# Generate code
stub <- build_function_stub(
  body_param_info = body_param_info,
  ...
)
```

### Anti-Patterns to Avoid

- **Early return without type classification:** Don't return `list(type = "unknown")` when schema type is determinable. Always classify as string, string_array, object, or array before returning.

- **Hardcoded batch limits:** Don't use `batch_limit = 200` in generated code. Use `Sys.getenv("batch_limit")` to allow runtime configuration (Requirement BATCH-01).

- **Missing parameter documentation:** Every parameter must have `#' @param` documentation. Use schema description field, fall back to generic descriptions.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OpenAPI reference resolution | Custom `$ref` parser | `resolve_schema_ref()` (already exists) | Handles circular references, depth limits, component lookup |
| Parameter name sanitization | Custom regex cleanup | `make.names()` + existing `sanitize_param()` | Ensures valid R identifiers, handles edge cases |
| Roxygen doc generation | Manual string building | `glue::glue()` with templates | Maintains consistent formatting, easier to read/maintain |
| String array collapsing | Custom paste logic | `paste(x, collapse = "\n")` | Standard R idiom, well-tested |
| Batch limit configuration | Hardcoded values | `Sys.getenv("batch_limit", "1000")` | Already used in generic_request(), allows runtime config |

**Key insight:** The stub generation pipeline already has 90% of the infrastructure needed. The fix is extending existing functions (`extract_body_properties()`, `build_function_stub()`) to handle simple types, not building new parsers from scratch.

## Common Pitfalls

### Pitfall 1: Type vs Schema Structure Confusion

**What goes wrong:** Treating body schema type as indicator of complexity, when a simple type can have complex validation rules.

**Why it happens:** OpenAPI allows string types to have patterns, enums, formats that make them "complex" from validation perspective but still simple from code generation perspective.

**How to avoid:**
- Check `schema[["type"]]` first (string, array, object)
- For arrays, check `items[["type"]]`
- Classification should be based on type hierarchy, not presence of validation keywords

**Warning signs:**
```r
# BAD: Assuming string with pattern is complex
if (!is.null(schema[["pattern"]])) {
  return(list(type = "unknown"))
}

# GOOD: Pattern doesn't change that it's a string
if (schema[["type"]] == "string") {
  # pattern, enum, format are metadata, not type indicators
  return(list(
    type = "string",
    properties = list(
      query = list(
        name = "query",
        type = "string",
        pattern = schema[["pattern"]],
        ...
      )
    )
  ))
}
```

### Pitfall 2: Missing Metadata Propagation

**What goes wrong:** Schema is correctly identified as simple type, but description/example metadata is lost, causing generated docs to be generic.

**Why it happens:** `extract_body_properties()` returns empty properties list for simple types, so downstream parsers have no metadata to work with.

**How to avoid:**
- Always populate `properties` list with at least one entry for simple types
- Use "query" or "word" as the parameter name (from schema or sensible default)
- Include description, example, enum from top-level schema

**Warning signs:**
```r
# In generated code - BAD
#' @param query Required parameter

# In generated code - GOOD
#' @param word Exact string of word to search for. Type: string
```

### Pitfall 3: Body-Only Detection Logic

**What goes wrong:** Simple body endpoints aren't detected as `is_body_only`, causing them to fall through to wrong code generation path.

**Why it happens:** `is_body_only` check in `build_function_stub()` (line 105-108) uses `body_param_info$has_params`, which is FALSE when properties list is empty.

**How to avoid:**
- Return `has_params = TRUE` for simple body types
- Set `primary_param` to the query parameter name
- Provide `fn_signature` with the parameter

**Warning signs:**
```r
# Check in build_function_stub() line 110
if (isTRUE(is_body_only)) {
  # This block should execute for simple body types
  # If it's not executing, body_param_info structure is wrong
}
```

### Pitfall 4: Newline Collapsing for POST Arrays

**What goes wrong:** Array of strings is sent as JSON array `["a", "b"]` when API expects newline-delimited string `"a\nb"`.

**Why it happens:** `generic_request()` uses `req_body_json()` which auto-serializes arrays to JSON arrays, not strings.

**How to avoid:**
- For simple string arrays, collapse before passing to generic_request
- Add collapse logic in generated function stub, not in generic_request
- Use `paste(query, collapse = "\n")` before calling generic_request

**Example fix:**
```r
# Generated function for POST with string array body
ct_function <- function(words) {
  # Collapse array to newline-delimited string
  body_string <- paste(words, collapse = "\n")

  result <- generic_request(
    query = body_string,
    endpoint = "endpoint/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "1000"))
  )
}
```

## Code Examples

Verified patterns from existing codebase:

### Example 1: Current Object Body Handling (Working)

```r
# Source: dev/endpoint_eval/01_schema_resolution.R:194-216
# This shows the pattern that WORKS for object schemas
extract_body_properties <- function(request_body, components) {
  # ... navigation code ...

  # If object, extract properties
  if (type == "object" && !is.null(json_schema[["properties"]])) {
    required_fields <- json_schema[["required"]] %||% character(0)

    metadata <- purrr::imap(json_schema[["properties"]], function(prop, prop_name) {
      list(
        name = prop_name,
        type = prop[["type"]] %||% NA,
        format = prop[["format"]] %||% NA,
        description = prop[["description"]] %||% "",
        enum = prop[["enum"]] %||% NULL,
        default = prop[["default"]] %||% NA,
        required = prop_name %in% required_fields,
        example = prop[["example"]] %||% prop[["default"]] %||% NA
      )
    })

    names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
    return(list(
      type = "object",
      properties = metadata
    ))
  }

  # PROBLEM: Falls through to unknown for simple types
  list(type = "unknown", properties = list())
}
```

### Example 2: Desired Simple String Handling (New)

```r
# Source: Pattern to add to extract_body_properties()
extract_body_properties <- function(request_body, components) {
  # ... navigation and resolution code ...

  type <- json_schema[["type"]] %||% NA

  # NEW: Handle simple string type
  if (type == "string") {
    # Create synthetic parameter metadata for the string body
    metadata <- list(
      query = list(  # Use generic name or extract from schema
        name = "query",
        type = "string",
        format = json_schema[["format"]] %||% NA,
        description = json_schema[["description"]] %||% "Query string",
        enum = json_schema[["enum"]] %||% NULL,
        default = json_schema[["default"]] %||% NA,
        required = TRUE,  # Body is typically required
        example = json_schema[["example"]] %||% NA
      )
    )

    return(list(
      type = "string",
      properties = metadata
    ))
  }

  # NEW: Handle array of strings
  if (type == "array" && !is.null(json_schema[["items"]])) {
    items <- json_schema[["items"]]

    # Simple array (e.g., string array)
    if (items[["type"]] == "string") {
      metadata <- list(
        query = list(
          name = "query",
          type = "array",
          item_type = "string",
          format = json_schema[["format"]] %||% NA,
          description = json_schema[["description"]] %||% "Array of strings",
          enum = json_schema[["enum"]] %||% NULL,
          default = json_schema[["default"]] %||% NA,
          required = TRUE,
          example = json_schema[["example"]] %||% NA
        )
      )

      return(list(
        type = "string_array",
        item_type = "string",
        properties = metadata
      ))
    }
  }

  # ... existing object and complex array handling ...
}
```

### Example 3: Function Signature Generation

```r
# Source: dev/endpoint_eval/07_stub_generation.R:110-133
# Shows how body-only endpoints generate signatures
build_function_stub <- function(..., body_param_info) {
  # ... request type detection ...

  if (isTRUE(is_body_only)) {
    # Body-only endpoint: primary param from body
    primary_param <- body_param_info$primary_param %||% "data"
    fn_signature <- body_param_info$fn_signature
    param_docs <- body_param_info$param_docs

    # Example value from body param metadata
    example_value <- example_query
    if (!is.null(body_param_info$primary_example) && !is.na(body_param_info$primary_example)) {
      example_value <- as.character(body_param_info$primary_example)
    }

    # For POST, use sample DTXSIDs
    if (isTRUE(method == "POST")) {
      dtxsids <- sample_test_dtxsids(n = 3)
      example_value_vec <- paste0('c("', paste(dtxsids, collapse = '", "'), '")')
    }
  }
}
```

### Example 4: Batch Limit from Environment

```r
# Source: R/z_generic_request.R:49-51
# Shows CORRECT pattern for batch limit
if (is.null(batch_limit) || batch_limit == "NA") {
  batch_limit <- as.numeric(Sys.getenv("batch_limit", "1000"))
}

# In generated stubs, should use:
result <- generic_request(
  query = query,
  endpoint = "endpoint/",
  method = "POST",
  batch_limit = as.numeric(Sys.getenv("batch_limit", "1000"))  # NOT hardcoded 200
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual function writing | OpenAPI-driven code generation | 2024 (estimated) | Faster endpoint coverage, consistent patterns |
| httr | httr2 | 2023 | Better error handling, pipe-friendly API |
| Hardcoded batch limits | Environment variable config | In progress | Runtime configuration, easier testing |
| Generic parameter docs | Schema-derived documentation | Partial (objects work, simple types don't) | Better user experience when complete |

**Deprecated/outdated:**
- `httr::POST()`: Replaced by `httr2::request()` + `req_method("POST")`
- Hardcoded batch values in function stubs: Should use `Sys.getenv("batch_limit")`

## Open Questions

Things that couldn't be fully resolved:

1. **Parameter Naming Convention for Simple Bodies**
   - What we know: Object properties have explicit names from schema
   - What's unclear: Simple string bodies have no property name - should we use "query", "word", "data", or extract from endpoint description?
   - Recommendation: Use generic "query" for consistency with path parameters, unless schema has explicit parameter name in description

2. **Newline vs Other Delimiters**
   - What we know: BODY-04 requirement specifies newline (`\n`) for string array collapsing
   - What's unclear: Is this universal for all CompTox APIs, or endpoint-specific?
   - Recommendation: Start with newline as default, add delimiter parameter if API testing shows variation

3. **Batch Limit for Simple Body POSTs**
   - What we know: Complex object POSTs use batch_limit for splitting large requests
   - What's unclear: Do simple string/array POSTs support batching the same way?
   - Recommendation: Use same batching strategy initially, adjust if API responds differently to simple bodies

## Sources

### Primary (HIGH confidence)
- ComptoxR codebase files:
  - `dev/endpoint_eval/01_schema_resolution.R` - extract_body_properties() implementation
  - `dev/endpoint_eval/04_openapi_parser.R` - openapi_to_spec() main parser
  - `dev/endpoint_eval/06_param_parsing.R` - parse_function_params() signature generation
  - `dev/endpoint_eval/07_stub_generation.R` - build_function_stub() code generation
  - `R/z_generic_request.R` - batch_limit environment variable usage
  - `R/ct_chemical_search_equal.R` - Example of correctly generated GET function

### Secondary (MEDIUM confidence)
- [OpenAPI Specification v3.0.3](https://spec.openapis.org/oas/v3.0.3.html) - Official OpenAPI spec for request body schemas
- [OpenAPI Content of Message Bodies](https://learn.openapis.org/specification/content.html) - Request body content types and schemas
- [httr2 Send data in request body](https://httr2.r-lib.org/reference/req_body.html) - req_body_json() documentation
- [roxygen2 Documenting functions](https://roxygen2.r-lib.org/articles/rd.html) - Parameter documentation patterns

### Tertiary (LOW confidence)
- [Swagger Describing Request Body](https://swagger.io/docs/specification/v3_0/describing-request-body/describing-request-body/) - Request body examples
- [Speakeasy Arrays in OpenAPI](https://www.speakeasy.com/openapi/schemas/arrays) - Array schema patterns
- [Speakeasy Strings in OpenAPI](https://www.speakeasy.com/openapi/schemas/strings) - String schema patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries verified in use in existing codebase
- Architecture: HIGH - Patterns extracted from working code, well-documented
- Pitfalls: HIGH - Identified from actual bug symptoms and codebase analysis

**Research date:** 2026-01-26
**Valid until:** 60 days (stable R ecosystem, OpenAPI spec unchanged since 2021)
