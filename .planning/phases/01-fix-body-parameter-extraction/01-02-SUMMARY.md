---
phase: 01-fix-body-parameter-extraction
plan: 02
subsystem: code-generation
tags: [stub-generation, simple-body-types, batch-limit, query-parameter]

requires:
  - phase: 01-fix-body-parameter-extraction
    plan: 01
    provides: extract_body_properties() with simple body type metadata

provides:
  - build_function_stub() generates correct function signatures for simple body types
  - Newline-delimited array collapse for string_array body types
  - Runtime-configurable batch_limit via Sys.getenv()

affects:
  - Future plans that generate API wrapper functions will have correct signatures
  - Endpoints with simple body schemas will work correctly

tech-stack:
  added: []
  patterns:
    - Simple body type detection via is_simple_body variable
    - Early return pattern for simple body code generation
    - Sys.getenv() pattern for runtime configurability

key-files:
  created: []
  modified:
    - dev/endpoint_eval/07_stub_generation.R

decisions:
  - id: simple-body-early-return
    what: Use early return for simple body types before existing code paths
    why: Prevents falling through to complex body handling logic
    impact: Cleaner code flow, easier to maintain

  - id: sysgetenv-batch-limit
    what: Use Sys.getenv("batch_limit", "1000") for bulk endpoints
    why: Allows runtime configuration without code changes
    impact: More flexible batching for different environments

metrics:
  tasks: 3
  commits: 3
  duration: ~4 minutes
  completed: 2026-01-27
---

# Phase 01 Plan 02: Stub Generation for Simple Body Types Summary

**One-liner:** Updated build_function_stub() to generate correct R function code with 'query' parameters, newline collapsing for arrays, and runtime-configurable batch limits for simple body type endpoints.

## What Was Built

Enhanced the stub generation system to handle simple body types (string and string_array) that were previously not generating correct function signatures.

### Task 1: is_body_only Detection Enhancement
- Added `is_simple_body` variable to detect "string" and "string_array" body schema types
- Works in both request_type path and legacy detection path
- Ensures simple body types are correctly identified for special handling

### Task 2: Simple Body Type Code Generation
- Added dedicated code generation path for simple body types
- Generates functions with `query` parameter for both string and string_array types
- Collapses string arrays with newline separator: `paste(query, collapse = "\n")`
- Uses `Sys.getenv("batch_limit", "1000")` for runtime configurability
- Returns early to avoid falling through to existing code paths
- Provides specific roxygen documentation for each body type

### Task 3: Batch Limit Configuration Pattern
- Updated batch_limit_code to use Sys.getenv() for bulk endpoints (batch_limit > 1)
- Static endpoints (batch_limit = 0) and path-based endpoints (batch_limit = 1) unchanged
- Aligns with pattern in R/z_generic_request.R

## Technical Implementation

**Code Generation Logic:**
```r
# Detection
is_simple_body <- body_schema_type %in% c("string", "string_array")

# Generation
if (isTRUE(is_simple_body)) {
  # Use "query" as primary parameter
  # Build type-specific documentation
  # Generate function body with optional newline collapse
  # Return early
}
```

**Example Output for String Array:**
```r
ct_test_array <- function(query) {
  # Collapse array to newline-delimited string for API
  body_string <- paste(query, collapse = "\n")

  result <- generic_request(
    query = body_string,
    endpoint = "test/array",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "1000"))
  )

  return(result)
}
```

## Testing Results

All verification tests passed:
- ✅ String body type generates function(query) signature
- ✅ String array body type includes newline collapse logic
- ✅ Both types use Sys.getenv("batch_limit", "1000")
- ✅ Correct roxygen documentation generated for each type

## Integration Points

**From Plan 01-01:**
- Receives body_schema_type = "string" or "string_array" from extract_body_properties()
- Uses synthetic "query" parameter metadata

**To Future Plans:**
- Generated functions ready for actual API endpoints
- Batch limit can be configured at runtime via environment variable

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| ed04848 | feat | Add simple body type detection in build_function_stub() |
| a95feb2 | feat | Add simple body type code generation path |
| 99a3512 | refactor | Use Sys.getenv pattern for batch_limit in bulk endpoints |

## Files Modified

**dev/endpoint_eval/07_stub_generation.R:**
- Lines 96-110: Added is_simple_body detection in both code paths
- Lines 356-442: Added simple body type code generation block (before is_body_only)
- Lines 34-43: Updated batch_limit_code to use Sys.getenv() for bulk endpoints

## Deviations from Plan

None - plan executed exactly as written.

## Known Issues

None identified.

## Next Phase Readiness

**Ready for Phase 2 (if applicable):** Yes

**Blockers:** None

**Recommendations:**
- Test with actual API endpoints that have simple body schemas
- Verify newline-delimited format matches API expectations
- Consider adding validation for query parameter types (string vs vector)

## Session Notes

**Duration:** ~4 minutes

**Challenges:**
- Initial test script hit segmentation fault due to R environment issues
- Resolved by using R CMD BATCH instead of inline execution

**Learnings:**
- Early return pattern keeps code generation paths independent
- Sys.getenv() pattern provides flexibility without breaking existing code
- Test output validation confirms correct stub generation

## Metadata

- **Plan Type:** Execute
- **Wave:** 2
- **Dependencies:** 01-01
- **Autonomous:** true
- **Completion Date:** 2026-01-27
