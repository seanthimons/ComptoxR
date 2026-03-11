# Phase 8: Reference Resolution - Research

**Researched:** 2026-01-29
**Domain:** JSON Schema Reference Resolution, OpenAPI/Swagger Schema Traversal
**Confidence:** HIGH

## Summary

This phase enhances the existing `resolve_schema_ref()` function to support both Swagger 2.0 (`#/definitions/`) and OpenAPI 3.0 (`#/components/schemas/`) reference paths with version-aware fallback behavior. Research confirms that JSON $ref resolution follows well-established patterns from JSON Schema and JSON Pointer specifications, with depth limit enforcement and circular reference detection being critical for production safety.

The codebase already has a working reference resolver (`resolve_schema_ref()` in `01_schema_resolution.R` lines 71-132) that handles OpenAPI 3.0 references, circular reference detection via environment tracking, and depth limits (max_depth=5). Phase 7 added version detection (`detect_schema_version()`) and separate Swagger 2.0 resolution (`resolve_swagger2_definition_ref()` lines 293-309). This phase unifies these approaches with intelligent fallback.

**Key finding:** The existing circular reference detection pattern (lines 97-115) uses R environments with sanitized keys and depth tracking - this approach should be extended, not replaced.

**Primary recommendation:** Enhance `resolve_schema_ref()` with version-aware fallback chain that checks primary location first (based on detected version), then alternate location, with full context in error messages when both fail.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| base R environments | R 4.x+ | Circular reference tracking | In-memory hash table, already used in codebase |
| purrr | latest | Nested list traversal | Already in use, functional iteration patterns |
| stringr | latest | Reference path parsing | Already in use, regex operations |
| cli | latest | Error reporting | Already in use, structured messages |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jsonlite | latest | Schema loading | Already used for JSON parsing |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Environment tracking | Global variable counter | Environments provide scoping and automatic cleanup with on.exit() |
| Manual path parsing | jsonpointer package | No CRAN package exists; stringr sufficient for JSON Pointer syntax |
| Custom depth tracking | Recursion limit options | R's recursion limit is too high (default 1000+), explicit depth needed |

**Installation:**
```r
# Already installed - no new dependencies
```

## Architecture Patterns

### Recommended Function Structure
```
01_schema_resolution.R
├── resolve_schema_ref()          # Enhanced with fallback chain (UPDATE)
├── resolve_swagger2_definition_ref()  # Kept for explicit Swagger 2.0 calls (KEEP)
└── resolve_stack environment     # Global tracking env (KEEP)
```

### Pattern 1: Version-Aware Fallback Chain
**What:** Primary location based on version, fallback to alternate location
**When to use:** When resolving any $ref, especially when version is ambiguous
**Example:**
```r
# Source: Derived from OpenAPI 3.0 spec and Swagger 2.0 spec patterns
resolve_schema_ref_with_fallback <- function(schema_ref, components, schema_version, max_depth = 5, depth = 0) {
  # Determine primary and secondary paths based on version
  if (!is.null(schema_version) && identical(schema_version$type, "swagger")) {
    primary_path <- "#/definitions/"
    secondary_path <- "#/components/schemas/"
    primary_container <- components  # Normalized to contain schemas
    secondary_container <- components$schemas %||% list()
  } else {
    # OpenAPI 3.0 or unknown - try components first
    primary_path <- "#/components/schemas/"
    secondary_path <- "#/definitions/"
    primary_container <- components$schemas %||% list()
    secondary_container <- components  # May have definitions
  }

  # Extract schema name from reference
  schema_name <- NULL
  if (grepl(paste0("^", primary_path), schema_ref)) {
    schema_name <- stringr::str_replace(schema_ref, paste0("^", primary_path), "")
  } else if (grepl(paste0("^", secondary_path), schema_ref)) {
    schema_name <- stringr::str_replace(schema_ref, paste0("^", secondary_path), "")
  }

  # Try primary location
  if (!is.null(schema_name) && !is.null(primary_container[[schema_name]])) {
    return(primary_container[[schema_name]])
  }

  # Try secondary location (fallback)
  if (!is.null(schema_name) && !is.null(secondary_container[[schema_name]])) {
    cli::cli_alert_info("Reference {schema_ref} resolved via fallback to alternate location")
    return(secondary_container[[schema_name]])
  }

  # Both failed - fatal error
  cli::cli_abort(c(
    "x" = "Cannot resolve schema reference: {.val {schema_ref}}",
    "i" = "Tried: {.path {primary_path}{schema_name}}, {.path {secondary_path}{schema_name}}",
    "i" = "Available schemas: {.val {names(primary_container)}}"
  ))
}
```

### Pattern 2: Circular Reference Detection with Environment
**What:** Track visited references with depth, detect when same ref visited at greater depth
**When to use:** Every reference resolution call
**Example:**
```r
# Source: Existing codebase pattern (01_schema_resolution.R lines 97-115)
resolve_stack <- new.env(hash = TRUE)

resolve_with_circular_detection <- function(schema_ref, components, depth = 0) {
  # Sanitize ref for use as R environment key
  sanitized_key <- gsub("[^a-zA-Z0-9]", "_", schema_ref)

  # Check if we've seen this reference before
  if (exists(sanitized_key, envir = resolve_stack)) {
    existing_depth <- get(sanitized_key, envir = resolve_stack)
    if (depth > existing_depth) {
      # Circular reference detected
      cli::cli_warn(c(
        "!" = "Circular reference detected: {.val {schema_ref}}",
        "i" = "Current depth: {depth}, Previous depth: {existing_depth}",
        "i" = "Returning partial schema"
      ))
      return(list(type = "circular_ref", ref = schema_ref))
    }
  }

  # Track this reference
  assign(sanitized_key, depth, envir = resolve_stack)
  on.exit({
    if (exists(sanitized_key, envir = resolve_stack)) {
      rm(sanitized_key, envir = resolve_stack)
    }
  }, add = TRUE)

  # ... proceed with resolution ...
}
```

### Pattern 3: Depth Limit Enforcement
**What:** Hard limit at depth=3, abort resolution with clear error
**When to use:** Every recursive call
**Example:**
```r
# Source: Derived from existing max_depth pattern
resolve_with_depth_limit <- function(schema_ref, components, max_depth = 3, depth = 0) {
  # Check depth limit (fail fast)
  if (depth > max_depth) {
    cli::cli_abort(c(
      "x" = "Reference depth limit exceeded: {.val {max_depth}}",
      "i" = "Current reference: {.val {schema_ref}}",
      "i" = "This may indicate circular references or overly complex schema",
      "i" = "Consider simplifying schema structure or reporting as bug"
    ))
  }

  # ... proceed with resolution at depth ...
  # When recursing:
  resolve_with_depth_limit(nested_ref, components, max_depth, depth + 1)
}
```

### Pattern 4: CLI Error Messages with Full Context
**What:** Structured error messages using cli package with endpoint/method context
**When to use:** All error conditions
**Example:**
```r
# Source: cli package documentation and CONTEXT.md decisions
report_resolution_failure <- function(ref, endpoint_route, endpoint_method, locations_tried) {
  cli::cli_abort(c(
    "x" = "Failed to resolve schema reference",
    "i" = "Reference: {.val {ref}}",
    "i" = "Endpoint: {.code {endpoint_method} {endpoint_route}}",
    "i" = "Locations tried: {.path {locations_tried}}",
    "i" = "Schema may be malformed or reference may be incorrect"
  ))
}

# Usage in openapi_to_spec context:
tryCatch(
  resolve_schema_ref(ref, components, schema_version),
  error = function(e) {
    report_resolution_failure(ref, route, method, c("#/definitions/Foo", "#/components/schemas/Foo"))
  }
)
```

### Pattern 5: Aggregate Error Collection
**What:** Collect all resolution failures for an endpoint, report together
**When to use:** When processing multiple references in a single endpoint
**Example:**
```r
# Source: Derived from CONTEXT.md requirement to collect failures
resolve_all_refs_in_endpoint <- function(operation, components, schema_version, route, method) {
  failures <- list()

  # Process request body refs
  if (!is.null(operation$requestBody)) {
    tryCatch({
      resolve_body_refs(operation$requestBody, components, schema_version)
    }, error = function(e) {
      failures <<- c(failures, list(list(location = "requestBody", error = e$message)))
    })
  }

  # Process parameter refs
  for (param in operation$parameters %||% list()) {
    if (!is.null(param$schema[["$ref"]])) {
      tryCatch({
        resolve_schema_ref(param$schema[["$ref"]], components, schema_version)
      }, error = function(e) {
        failures <<- c(failures, list(list(location = param$name, error = e$message)))
      })
    }
  }

  # Report all failures together
  if (length(failures) > 0) {
    cli::cli_abort(c(
      "x" = "Endpoint has {length(failures)} unresolved reference{?s}",
      "i" = "Endpoint: {.code {method} {route}}",
      "!" = purrr::map_chr(failures, ~ paste0(.x$location, ": ", .x$error))
    ))
  }
}
```

### Anti-Patterns to Avoid
- **Silent fallback:** Don't silently use fallback location - always log when alternate path is used (aids debugging schema issues)
- **Ignoring depth:** Don't skip depth tracking for "simple" schemas - all refs must be tracked
- **Generic error messages:** Don't use simple `stop()` - use cli::cli_abort() with full context
- **String comparison for refs:** Don't use exact string matching - parse path components properly

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Circular reference detection | Manual visited set | Environment with depth tracking | R environments provide scoping, automatic cleanup with on.exit() |
| Reference path parsing | Complex regex | stringr::str_replace() with fixed prefixes | JSON Pointer uses fixed patterns (#/path/to/item) |
| Error message formatting | paste() strings | cli::cli_abort() with vectors | cli handles pluralization, styling, structure automatically |
| Depth tracking | Global counter | Function parameter + environment | Function param explicit, environment prevents cross-call pollution |

**Key insight:** The existing `resolve_schema_ref()` function already solves the hard problems (circular detection, depth limits). Enhance it with version awareness rather than rewriting from scratch.

## Common Pitfalls

### Pitfall 1: Assuming Version Always Known
**What goes wrong:** schema_version is NULL or unknown when resolve_schema_ref() is called
**Why it happens:** Edge cases like partial schemas, embedded schemas, or test fixtures
**How to avoid:** Default to OpenAPI 3.0 behavior when version unknown, but try fallback
**Warning signs:** schema_version$type == "unknown" or is.null(schema_version)

### Pitfall 2: Not Logging Fallback Usage
**What goes wrong:** Silent fallback hides schema authoring issues
**Why it happens:** Developer assumes fallback is an error path, not normal operation
**How to avoid:** Always log when fallback location is used (not just verbose mode)
**Warning signs:** User reports "schema works but something seems wrong"

### Pitfall 3: Circular References Without Depth Tracking
**What goes wrong:** Stack overflow from A → B → A reference loops
**Why it happens:** Checking existence without tracking depth
**How to avoid:** Track depth per reference, detect when revisiting at greater depth
**Warning signs:** R session crashes with "C stack usage" error

### Pitfall 4: Malformed Reference Paths
**What goes wrong:** Reference like "definitions/Schema" (missing #) or "#/schema/Name" (wrong path)
**Why it happens:** Schema authoring errors, manual editing
**How to avoid:** Validate reference format before parsing, abort with clear error
**Warning signs:** stringr::str_replace() returns unchanged input (regex didn't match)

### Pitfall 5: Missing Schema Names
**What goes wrong:** Reference path parses but schema name is empty string
**Why it happens:** Trailing slash in ref like "#/definitions/" or "#/components/schemas/"
**How to avoid:** Check nzchar(schema_name) after extraction
**Warning signs:** Lookup with empty string returns NULL, error message shows blank name

### Pitfall 6: External File References
**What goes wrong:** Reference like "other-file.json#/components/schemas/Schema"
**Why it happens:** Multi-file OpenAPI specs common in some tools
**How to avoid:** Detect file prefix before #, abort with "external refs not supported" error
**Warning signs:** Reference contains ".json" or ".yaml" before # character

### Pitfall 7: Empty Resolved Schemas
**What goes wrong:** Reference resolves to {} or list() (valid but useless)
**Why it happens:** Schema defined but contains no properties/type
**How to avoid:** Warn but continue (may be intentional placeholder)
**Warning signs:** !is.null(schema) but length(schema) == 0 or (is.null(schema$type) && is.null(schema$properties))

## Code Examples

Verified patterns from official sources and existing codebase:

### OpenAPI 3.0 Reference Format
```json
// Source: https://spec.openapis.org/oas/v3.0.3
{
  "paths": {
    "/pets": {
      "post": {
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/Pet"
              }
            }
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "Pet": {
        "type": "object",
        "properties": {
          "name": {"type": "string"}
        }
      }
    }
  }
}
```

### Swagger 2.0 Reference Format
```json
// Source: https://swagger.io/docs/specification/v2_0/
{
  "paths": {
    "/pets": {
      "post": {
        "parameters": [{
          "in": "body",
          "schema": {
            "$ref": "#/definitions/Pet"
          }
        }]
      }
    }
  },
  "definitions": {
    "Pet": {
      "type": "object",
      "properties": {
        "name": {"type": "string"}
      }
    }
  }
}
```

### Nested References Example
```json
// Source: Real-world OpenAPI pattern
{
  "components": {
    "schemas": {
      "SearchRequest": {
        "type": "object",
        "properties": {
          "chemicals": {
            "type": "array",
            "items": {
              "$ref": "#/components/schemas/Chemical"
            }
          }
        }
      },
      "Chemical": {
        "type": "object",
        "properties": {
          "identifiers": {
            "$ref": "#/components/schemas/Identifiers"
          }
        }
      },
      "Identifiers": {
        "type": "object",
        "properties": {
          "dtxsid": {"type": "string"}
        }
      }
    }
  }
}
```
Depth: SearchRequest (0) → Chemical (1) → Identifiers (2) = Valid (< 3)

### Enhanced resolve_schema_ref() Signature
```r
# Source: Existing codebase + Phase 8 requirements
resolve_schema_ref <- function(
  schema_ref,           # Reference string like "#/components/schemas/Pet"
  components,           # components object (OpenAPI 3.0) or definitions (Swagger 2.0)
  schema_version = NULL, # Version context from detect_schema_version()
  max_depth = 3,        # Depth limit (reduced from 5 to 3 per CONTEXT.md)
  depth = 0,            # Current recursion depth
  endpoint_context = NULL # Optional: list(route = "...", method = "...") for errors
) {
  # Implementation combines patterns above
}
```

### Reference Path Validation
```r
# Source: Derived from JSON Pointer and JSON Reference specs
validate_reference_path <- function(ref) {
  # Check basic format
  if (!grepl("^#/", ref)) {
    cli::cli_abort(c(
      "x" = "Invalid reference format: {.val {ref}}",
      "i" = "References must start with {.code #/}",
      "i" = "External file references are not supported"
    ))
  }

  # Check for external file refs
  if (grepl("\\.(json|yaml|yml)", ref)) {
    cli::cli_abort(c(
      "x" = "External file reference not supported: {.val {ref}}",
      "i" = "All schemas must be in single file",
      "i" = "Consider merging schemas or preprocessing with bundler"
    ))
  }

  # Check for valid path prefixes
  valid_prefixes <- c("#/components/schemas/", "#/definitions/")
  has_valid_prefix <- any(purrr::map_lgl(valid_prefixes, ~ grepl(paste0("^", .x), ref)))

  if (!has_valid_prefix) {
    cli::cli_warn(c(
      "!" = "Unusual reference path: {.val {ref}}",
      "i" = "Expected {.code #/components/schemas/} or {.code #/definitions/}",
      "i" = "Proceeding with caution"
    ))
  }

  TRUE
}
```

### Fallback Logging Pattern
```r
# Source: CONTEXT.md decision - always log fallback, not just verbose
log_fallback_resolution <- function(ref, primary_path, secondary_path, schema_name) {
  cli::cli_alert_info(c(
    "Reference resolved via fallback",
    "i" = "Reference: {.val {ref}}",
    "i" = "Primary location not found: {.path {primary_path}{schema_name}}",
    "i" = "Resolved from: {.path {secondary_path}{schema_name}}"
  ))
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual ref parsing | JSON Pointer standard | JSON Schema Draft 4 (2013) | Standardized path syntax |
| Separate resolvers | Unified resolver with fallback | This phase | Single function handles both versions |
| Silent failures | Structured error messages | This phase | Better debugging, clearer errors |
| Depth limit 5 | Depth limit 3 | This phase | Faster failure, encourages simpler schemas |

**Deprecated/outdated:**
- Hard-coded OpenAPI 3.0 paths in `resolve_schema_ref()` - will be enhanced with fallback
- Separate `resolve_swagger2_definition_ref()` - will remain but as wrapper for backward compat

## Open Questions

Things that couldn't be fully resolved:

1. **Depth Limit Behavior on Truncate vs Fail**
   - What we know: Depth limit should be 3 (CONTEXT.md)
   - What's unclear: Should we truncate and warn, or abort?
   - Recommendation: **Abort with error** - truncated schemas lead to silent bugs; explicit failure forces schema simplification
   - Confidence: MEDIUM - CONTEXT.md gives Claude discretion but abort is safer

2. **Depth Tracking Logging Verbosity**
   - What we know: Should log depth tracking somehow
   - What's unclear: How verbose? Every recursion? Only near limit?
   - Recommendation: **Log only when depth > 1** - shows nested resolution without spam
   - Confidence: MEDIUM - CONTEXT.md gives Claude discretion

3. **Schema Normalization for Swagger 2.0**
   - What we know: Phase 7 normalizes definitions as components (line 348)
   - What's unclear: Does this make fallback unnecessary for Swagger 2.0?
   - Recommendation: **Keep fallback anyway** - handles edge cases, no performance cost
   - Confidence: HIGH - normalization happens in openapi_to_spec(), not in all callers

## Sources

### Primary (HIGH confidence)
- [OpenAPI 3.0 Using $ref](https://swagger.io/docs/specification/v3_0/using-ref/) - Official reference documentation
- [OpenAPI Specification v3.0.3](https://spec.openapis.org/oas/v3.0.3) - Reference Object specification
- [Swagger 2.0 Specification](https://swagger.io/docs/specification/v2_0/) - Definition Object patterns
- Existing codebase: `01_schema_resolution.R` lines 71-309 (resolve_schema_ref, circular detection)
- Existing codebase: `04_openapi_parser.R` lines 340-341 (version detection integration)

### Secondary (MEDIUM confidence)
- [cli::cli_abort() documentation](https://cli.r-lib.org/reference/cli_abort.html) - Error message formatting
- [JSON Schema $Ref Parser](https://apitools.dev/json-schema-ref-parser/docs/) - Circular reference patterns (JavaScript but patterns apply)
- [Advanced R - Environment Recursion](https://bookdown.dongzhuoer.com/hadley/adv-r/env-recursion) - R environment tracking patterns
- WebSearch: JSON schema circular reference detection best practices

### Tertiary (LOW confidence)
- None - all findings verified against specifications or existing codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - using existing R features and libraries already in codebase
- Architecture: HIGH - patterns extend existing proven code, minimal changes
- Pitfalls: HIGH - based on JSON Reference spec constraints and existing codebase experience
- Edge cases: MEDIUM - some ambiguity around depth limit behavior (Claude's discretion)

**Research date:** 2026-01-29
**Valid until:** Stable (spec-based, unlikely to change)

## Codebase-Specific Findings

### Existing Reference Resolution Infrastructure

**Current implementation (01_schema_resolution.R lines 71-132):**
- ✓ Circular reference detection via `resolve_stack` environment
- ✓ Depth limit enforcement (max_depth parameter)
- ✓ Sanitized environment keys for special characters
- ✓ Automatic cleanup with on.exit()
- ✗ No version-aware fallback (only checks #/components/schemas/)
- ✗ Generic errors (uses stop(), not cli::cli_abort())

**Swagger 2.0 resolver (01_schema_resolution.R lines 293-309):**
- ✓ Parses #/definitions/ references
- ✓ Validates reference format
- ✗ No circular detection
- ✗ No depth tracking
- ✗ Returns NULL on failure (silent)

### Integration Points

**Where resolve_schema_ref() is called:**
1. `extract_body_properties()` line 330 - resolves requestBody schema refs
2. `extract_body_properties()` line 364 - resolves array items refs
3. `extract_query_params_with_refs()` line 500 - resolves query parameter refs
4. `extract_query_params_with_refs()` line 529 - resolves nested property refs

**Phase 8 changes needed:**
- Add `schema_version` parameter to all resolve_schema_ref() calls
- Thread version context from `openapi_to_spec()` down to resolution calls
- Update error messages to use cli::cli_abort() with context
- Add fallback chain logic to try alternate location

### Version Context Flow

```
openapi_to_spec()
  ↓ (detects version)
schema_version = detect_schema_version(openapi)
  ↓
extract_body_properties(request_body, components, schema_version)
  ↓
resolve_schema_ref(ref, components, schema_version, ...)
```

Version context must be threaded through this entire chain (REQ-02).

### CLI Package Usage in Codebase

**Already using cli for messages:**
- `cli::cli_alert_info()` - 25 occurrences in dev/endpoint_eval/
- `cli::cli_alert_warning()` - 10 occurrences
- `cli::cli_alert_success()` - 13 occurrences
- `cli::cli_alert_danger()` - 3 occurrences
- `cli::cli_h2()` - 9 occurrences (section headers)

**NOT using cli for errors:**
- Current code uses `stop()` in resolve_schema_ref() line 74
- Should migrate to `cli::cli_abort()` for consistency

### Test Coverage Patterns

**Existing verification scripts:**
- `verify_phase7.R` - Tests Swagger 2.0 resolution (line 76-78)
- `verify_07-02_integration.R` - Cross-version testing
- Pattern: Use real schemas from schema/ directory
- Pattern: Check both positive cases (resolution works) and error cases (malformed refs)

**Phase 8 testing should verify:**
- REF-01: Fallback from definitions → components and vice versa
- REF-02: Version context flows through entire chain
- REF-03: Nested refs resolve up to depth 3, fail at depth 4
- Circular refs detected and handled
- Error messages include full context (endpoint, locations tried)
