---
phase: 07-version-detection
plan: 02
subsystem: schema-parsing
completed: 2026-01-29
duration: 4min
tags: [swagger2.0, openapi3.0, version-detection, parser-pipeline, body-extraction]

requires:
  - phase: "07-01"
    provides: "Version detection functions (detect_schema_version, extract_swagger2_body_schema)"

provides:
  - "Version-aware openapi_to_spec() entry point"
  - "Schema version logging during parsing"
  - "Automatic routing to Swagger 2.0 vs OpenAPI 3.0 extraction logic"
  - "Version-aware has_body detection (body parameter vs requestBody)"
  - "Fixed Swagger 2.0 object detection for schemas without explicit type field"

affects:
  - "07-03: Body parameter extraction will use this version-aware pipeline"
  - "09-01: Stub regeneration will use version-aware parser for all schemas"

tech-stack:
  added: []
  patterns:
    - "Schema version detection at pipeline entry point"
    - "Version-aware extraction dispatch based on schema type"
    - "Implicit object type detection for Swagger 2.0 schemas with properties"

key-files:
  created:
    - "dev/endpoint_eval/verify_07-02_task1-2.R"
    - "dev/endpoint_eval/verify_07-02_task3.R"
    - "dev/endpoint_eval/verify_07-02_integration.R"
  modified:
    - "dev/endpoint_eval/04_openapi_parser.R"
    - "dev/endpoint_eval/01_schema_resolution.R"

key-decisions:
  - "VERS-ROUTE: Call detect_schema_version() at openapi_to_spec() entry point"
  - "SWAGGER-DEFS: For Swagger 2.0, normalize definitions as components for compatibility"
  - "IMPLICIT-OBJ: Detect object type from presence of properties field when type is missing"

patterns-established:
  - "Version detection before any parsing logic"
  - "Conditional extraction based on schema_version$type"
  - "Inline schema type inference for Swagger 2.0 compatibility"

metrics:
  duration: 4min
  completed: 2026-01-29
---

# Phase 7 Plan 02: Version Detection Pipeline Integration Summary

**OpenAPI parser now detects schema versions at entry point and routes to appropriate Swagger 2.0 or OpenAPI 3.0 extraction logic automatically**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-29T20:03:56Z
- **Completed:** 2026-01-29T20:08:07Z
- **Tasks:** 3
- **Files modified:** 2

## What Was Built

Integrated version detection from 07-01 into the main openapi_to_spec() parser pipeline, enabling automatic detection and routing for Swagger 2.0 and OpenAPI 3.0 schemas.

### Key Components

**1. Entry Point Version Detection**
- `openapi_to_spec()` calls `detect_schema_version()` immediately after preprocessing
- Logs detected version: "Detected schema version: swagger 2.0" or "openapi 3.x.x"
- Sets up definitions/components based on detected version

**2. Version-Aware Body Extraction**
- For Swagger 2.0: Passes `op$parameters` and `definitions` to extraction
- For OpenAPI 3.0: Passes `op$requestBody` and `components` to extraction
- Extraction function routes based on `schema_version` parameter

**3. Version-Aware has_body Detection**
- Swagger 2.0: Checks for `in="body"` in parameters array
- OpenAPI 3.0: Checks for `requestBody` object presence
- Correctly identifies POST endpoints with body for both versions

**4. Version-Aware body_schema_type**
- Swagger 2.0: Derives type from body_props (already extracted)
- OpenAPI 3.0: Calls get_body_schema_type() as before
- Avoids duplicate schema traversal

**5. Fixed Swagger 2.0 Object Detection**
- Swagger 2.0 schemas often omit `type: "object"` when properties field is present
- Updated extract_swagger2_body_schema() to infer object type from properties
- Enables correct extraction for schemas like BatchSearchGeneralRequest

## Accomplishments

- Version detection integrated at parser entry point with logging
- Body extraction correctly routes to Swagger 2.0 vs OpenAPI 3.0 logic
- All Swagger 2.0 schemas (AMOS, RDKit, Mordred) parse with body params extracted
- All OpenAPI 3.0 schemas (chemi-resolver, ctx-chemical) parse with no regression
- has_body detection works correctly for both schema versions

## Task Commits

Each task was committed atomically:

1. **Tasks 1-2: Version detection and has_body** - `7aa27fa` (feat)
2. **Task 3: Verify OpenAPI 3.0 no regression** - `5cdb33c` (test)

## Files Created/Modified

**Created:**
- `dev/endpoint_eval/verify_07-02_task1-2.R` - Task 1-2 verification script
- `dev/endpoint_eval/verify_07-02_task3.R` - OpenAPI 3.0 regression test
- `dev/endpoint_eval/verify_07-02_integration.R` - Comprehensive integration test

**Modified:**
- `dev/endpoint_eval/04_openapi_parser.R` - Added version detection at entry, version-aware extraction dispatch, version-aware has_body/body_schema_type
- `dev/endpoint_eval/01_schema_resolution.R` - Fixed object detection for schemas with properties but no explicit type field

## Decisions Made

**VERS-ROUTE: Version detection at entry point**
- Called detect_schema_version() immediately after preprocessing in openapi_to_spec()
- Ensures all downstream extraction uses correct version-specific logic
- Alternative: Pass schema version through every function call (more invasive)

**SWAGGER-DEFS: Normalize definitions as components**
- For Swagger 2.0, wrap definitions in `list(schemas = definitions)` structure
- Enables compatibility with resolve_schema_ref which expects components$schemas
- Avoids duplicating reference resolution logic

**IMPLICIT-OBJ: Infer object type from properties**
- Swagger 2.0 schemas often omit `type: "object"` when properties field exists
- Updated detection: `is_object <- (!is.na(schema_type) && schema_type == "object") || (is.na(schema_type) && has_properties)`
- Enables correct extraction for implicitly-typed object schemas

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Swagger 2.0 object detection for implicit types**
- **Found during:** Task 1 (Testing Swagger 2.0 body extraction)
- **Issue:** extract_swagger2_body_schema() required explicit `type: "object"` but Swagger 2.0 schemas often omit this field when properties exist
- **Fix:** Added implicit object detection - if schema has properties but no type, infer type="object"
- **Files modified:** dev/endpoint_eval/01_schema_resolution.R
- **Verification:** AMOS batch_search endpoint now extracts 10 body parameters correctly
- **Committed in:** 7aa27fa (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Essential fix for Swagger 2.0 compatibility. Swagger 2.0 spec allows implicit object type when properties field is present.

## Issues Encountered

None - all tasks executed as planned after the implicit object type fix.

## Verification Results

**Integration test results:**
- ✅ AMOS (Swagger 2.0): 15 POST endpoints with body params
- ✅ RDKit (Swagger 2.0): 1 POST endpoint
- ✅ Mordred (Swagger 2.0): 1 POST endpoint
- ✅ chemi-resolver-prod (OpenAPI 3.1.0): 11 POST endpoints with body params
- ✅ ctx-chemical-prod (OpenAPI 3.1.0): 11 POST endpoints with body params
- ✅ Preflight endpoints correctly excluded
- ✅ No regression in OpenAPI 3.0 parsing

**Requirements satisfied:**
- VERS-03: Version detection routes to appropriate extraction logic ✅
- BODY-02: OpenAPI 3.0 body extraction verified with stopifnot assertions ✅

## Next Phase Readiness

**Ready for:**
- 07-03: Reference resolution enhancement (parser pipeline fully version-aware)
- 09-01: Stub regeneration (all schemas parse correctly with version detection)

**Dependencies satisfied:**
- All Swagger 2.0 microservice schemas parse correctly
- All OpenAPI 3.0 schemas parse with no regression
- Version logging enables debugging of schema-specific issues

**No blockers or concerns.**

---
*Phase: 07-version-detection*
*Completed: 2026-01-29*
