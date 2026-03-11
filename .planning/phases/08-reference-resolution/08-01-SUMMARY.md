---
phase: 08-reference-resolution
plan: 01
subsystem: schema-processing
tags: [reference-resolution, version-aware, fallback-chain, depth-limit, cli-errors]
requires: [07-01, 07-02]
provides: [enhanced-resolve-schema-ref, validate-schema-ref]
affects: [08-02]
decisions:
  - id: REF-VALIDATE
    what: Created validate_schema_ref() as separate validation function
    why: Separation of concerns - validation before resolution logic
    impact: Cleaner error messages, reusable validation
  - id: REF-FALLBACK-LOG
    what: Fallback usage logged with cli::cli_alert_info() (always visible)
    why: Important for debugging cross-version schema issues
    impact: Users see when fallback chain is used
  - id: REF-DEPTH-3
    what: Reduced depth limit from 5 to 3
    why: Matches CONTEXT.md requirement, prevents overly complex schemas
    impact: May catch circular refs earlier, simpler resolution
tech-stack:
  added: []
  patterns:
    - name: version-aware-fallback
      description: Primary/secondary location selection based on schema version
    - name: cli-structured-errors
      description: All errors use cli::cli_abort() with context bullets
key-files:
  created:
    - path: dev/endpoint_eval/verify_08-01.R
      purpose: Comprehensive verification of reference resolution
  modified:
    - path: dev/endpoint_eval/01_schema_resolution.R
      changes:
        - Added validate_schema_ref() function
        - Enhanced resolve_schema_ref() with version-aware fallback
        - Reduced depth limit to 3
        - All errors use cli::cli_abort()
        - Updated extract_body_properties() to pass schema_version
        - Updated extract_query_params_with_refs() signature
metrics:
  duration: 8 minutes
  completed: 2026-01-29
---

# Phase 8 Plan 01: Reference Resolution Enhancement Summary

**One-liner:** Version-aware reference resolution with Swagger 2.0/OpenAPI 3.0 fallback chain, depth limit 3, and CLI-based error handling

## What Was Delivered

Enhanced `resolve_schema_ref()` to intelligently handle both Swagger 2.0 (`#/definitions/`) and OpenAPI 3.0 (`#/components/schemas/`) reference formats with automatic fallback when the primary location fails.

**Key enhancements:**

1. **REF-01: Version-aware fallback chain**
   - Swagger 2.0: Try `#/definitions/` first, then `#/components/schemas/`
   - OpenAPI 3.0: Try `#/components/schemas/` first, then `#/definitions/`
   - Fallback usage logged with `cli::cli_alert_info()` (always visible, not just verbose mode)

2. **REF-02: Version context parameter**
   - Added `schema_version` parameter to `resolve_schema_ref()`
   - Flows through from `detect_schema_version()` at pipeline entry
   - Enables intelligent path selection based on detected version

3. **REF-03: Depth limit reduction**
   - Reduced from 5 to 3 (per CONTEXT.md requirement)
   - Prevents overly complex schema nesting
   - Clearer error messages when limit exceeded

4. **Validation and error handling**
   - New `validate_schema_ref()` function checks:
     * Must start with `#/` (internal reference only)
     * No external file references (`file.json#/...`)
     * Valid path prefixes (`#/components/schemas/` or `#/definitions/`)
     * Non-empty schema names
   - All errors use `cli::cli_abort()` with structured context bullets
   - Includes endpoint context when available

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Add reference validation helper function | 566267a | 01_schema_resolution.R |
| 2 | Enhance resolve_schema_ref() with version-aware fallback | a007bd1 | 01_schema_resolution.R |
| 3 | Create verification script and test edge cases | 8c39eac | verify_08-01.R |

## Requirements Satisfied

- **REF-01**: Version-aware fallback chain (primary → secondary location based on schema version)
- **REF-02**: `schema_version` parameter flows through resolution
- **REF-03**: Depth limit reduced to 3, enforced with clear errors
- **Error handling**: All validation and resolution errors use `cli::cli_abort()` with full context

## Technical Implementation

### validate_schema_ref()

```r
validate_schema_ref(ref, endpoint_context = NULL)
```

**Validates:**
- Non-empty character string
- Starts with `#/` (internal reference)
- No external file references
- Valid path prefixes
- Non-empty schema name

**Returns:** TRUE or aborts with structured error

### Enhanced resolve_schema_ref()

```r
resolve_schema_ref(schema_ref, components, schema_version = NULL,
                   max_depth = 3, depth = 0, endpoint_context = NULL)
```

**New parameters:**
- `schema_version`: List with `type` ("swagger" | "openapi" | "unknown")
- `endpoint_context`: Optional list with `method` and `route` for error context
- `max_depth`: Default now 3 (was 5)

**Version-aware logic:**
- Swagger 2.0: `primary_path = "#/definitions/"`, `secondary_path = "#/components/schemas/"`
- OpenAPI 3.0: `primary_path = "#/components/schemas/"`, `secondary_path = "#/definitions/"`
- Unknown: Defaults to OpenAPI 3.0 behavior

**Fallback chain:**
1. Try `primary_container[[schema_name]]`
2. If not found, try `secondary_container[[schema_name]]`
3. If found in secondary, log with `cli::cli_alert_info()`
4. If both fail, abort with `cli::cli_abort()` listing locations tried

### Updated Callers

**extract_body_properties():**
- Now passes `schema_version` to `resolve_schema_ref()`
- Uses `max_depth = 3`

**extract_query_params_with_refs():**
- Added `schema_version` parameter
- Passes to all `resolve_schema_ref()` calls
- Uses `max_depth = 3`

## Testing

### Verification Coverage

**verify_08-01.R** tests:
1. Swagger 2.0 `#/definitions/` resolution
2. OpenAPI 3.0 `#/components/schemas/` resolution
3. Malformed reference validation (missing `#`, external files, empty names)
4. Depth limit enforcement (max_depth = 3)
5. Shallow nesting works (depth 2)
6. Circular reference detection
7. Version-aware fallback chain (cross-location references)
8. Version context parameter usage

**All tests pass.**

### Edge Cases Handled

- **Circular references**: Detected via `resolve_stack` environment, returns partial schema with warning
- **Empty schemas**: Warning issued if resolved schema has no type/properties/$ref
- **Nested $ref**: Resolved recursively with depth tracking
- **Schema composition**: `allOf` handled by resolving first element
- **Missing schemas**: Clear error listing locations tried and available schemas

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

**Ready for Phase 8 Plan 02** (Integration with Body Extraction):
- `resolve_schema_ref()` enhanced and verified
- `extract_body_properties()` already updated to pass `schema_version`
- `extract_query_params_with_refs()` signature updated

**Blockers:** None

**Concerns:** None - all edge cases tested and handled

## Files Modified

```
dev/endpoint_eval/
├── 01_schema_resolution.R    [Enhanced: +110 lines, -43 lines]
│   ├── validate_schema_ref()         [NEW]
│   ├── resolve_schema_ref()          [ENHANCED]
│   ├── extract_body_properties()     [UPDATED]
│   └── extract_query_params_with_refs() [UPDATED]
└── verify_08-01.R             [NEW: +197 lines]
    └── Comprehensive verification suite
```

## Lessons Learned

1. **cli::cli_abort() error structure**: Full message is in `conditionMessage(err)`, not `err$message` alone
2. **Fallback logging visibility**: Always-visible logging (not verbose-only) is important for cross-version debugging
3. **Depth limit tuning**: 3 levels is sufficient for well-designed schemas, catches problems earlier
4. **Validation separation**: Separate validation function makes error messages clearer and logic more maintainable

## Alignment with Requirements

- ✅ **REF-01**: Fallback chain implemented and tested
- ✅ **REF-02**: Version context flows through resolution
- ✅ **REF-03**: Depth limit reduced to 3
- ✅ **Error handling**: All errors use cli::cli_abort()
- ✅ **Validation**: Edge cases handled (malformed refs, external files, empty names)

**Phase 8 Plan 01 is complete and verified.**
