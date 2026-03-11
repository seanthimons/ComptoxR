---
phase: 07-version-detection
plan: 01
subsystem: schema-parsing
completed: 2026-01-29
duration: 2.3min
tags: [swagger2.0, openapi3.0, version-detection, body-extraction, schema-resolution]

requires:
  - "06-01: Endpoint detection infrastructure"
  - "Existing schema resolution module (01_schema_resolution.R)"

provides:
  - "Version detection for Swagger 2.0 and OpenAPI 3.0 schemas"
  - "Swagger 2.0 body parameter extraction from parameters[] array"
  - "Reference resolution for #/definitions/ (Swagger 2.0)"
  - "Version-aware extraction dispatch in extract_body_properties()"

affects:
  - "07-02: Will use detect_schema_version() for schema type identification"
  - "09-01: Stub regeneration will test both Swagger 2.0 and OpenAPI 3.0 extraction"

tech-stack:
  added: []
  patterns:
    - "Schema version detection via swagger/openapi root fields"
    - "Specification validation (single body param, body/formData exclusivity)"
    - "Dual extraction paths (Swagger 2.0 vs OpenAPI 3.0)"

key-files:
  created:
    - "dev/endpoint_eval/verify_07-01.R"
  modified:
    - "dev/endpoint_eval/00_config.R"
    - "dev/endpoint_eval/01_schema_resolution.R"

decisions:
  - id: VERS-DETECT
    what: "Version detection strategy"
    why: "Need to identify Swagger 2.0 vs OpenAPI 3.0 for correct extraction"
    choice: "Check swagger/openapi root fields with regex version matching"
    alternatives:
      - "Parse version strings fully"
      - "Assume version from file metadata"
    rationale: "Simple regex check is robust and handles edge cases (2.x, 3.x variants)"

  - id: SWAGGER2-BODY
    what: "Swagger 2.0 body extraction approach"
    why: "Swagger 2.0 uses parameters[].in='body' instead of requestBody"
    choice: "New function extract_swagger2_body_schema() with parameters array input"
    alternatives:
      - "Extend existing extract_body_properties() with conditionals"
      - "Transform Swagger 2.0 to OpenAPI 3.0 structure first"
    rationale: "Separate function maintains clarity and allows spec-specific validation"

  - id: VERSION-DISPATCH
    what: "Integration point for version-aware extraction"
    why: "Need single entry point that handles both schema versions"
    choice: "Add optional schema_version parameter to extract_body_properties()"
    alternatives:
      - "Create wrapper function for unified interface"
      - "Require callers to choose extraction function"
    rationale: "Backward compatible, minimal API surface change, clear dispatch logic"

metrics:
  lines_added: 182
  lines_modified: 2
  functions_added: 3
  commits: 3
---

# Phase 7 Plan 01: Version Detection and Swagger 2.0 Body Extraction Summary

**One-liner:** Schema parser now detects Swagger 2.0 vs OpenAPI 3.0 and extracts body parameters from parameters[] arrays with #/definitions/ resolution

## What Was Built

Added version detection and Swagger 2.0 body extraction capabilities to the schema parsing module, enabling correct parameter extraction from both Swagger 2.0 microservices (AMOS, RDKit, Mordred) and OpenAPI 3.0 APIs (CTX Dashboard).

### Key Components

**1. Version Detection (detect_schema_version)**
- Detects Swagger 2.0 via `swagger: "2.0"` root field
- Detects OpenAPI 3.0 via `openapi: "3.x.x"` root field
- Returns structured version info: `{version: "2.0", type: "swagger"}`
- Handles unknown/missing version indicators gracefully

**2. Swagger 2.0 Body Extraction (extract_swagger2_body_schema)**
- Extracts body schema from `parameters[].in="body"` arrays
- Resolves `#/definitions/{SchemaName}` references via new helper
- Validates Swagger 2.0 spec constraints:
  - **BODY-05:** Single body parameter (warns on violations)
  - **BODY-06:** Body/formData mutual exclusivity (warns on violations)
- Supports inline schemas (BODY-04) and reference resolution (BODY-03)
- Handles object, array, and string body types with property metadata

**3. Reference Resolution (resolve_swagger2_definition_ref)**
- Resolves Swagger 2.0 `#/definitions/` references (not `#/components/schemas/`)
- Validates reference format and definition existence
- Returns resolved schema definition or NULL on failure

**4. Version-Aware Dispatch**
- Updated `extract_body_properties()` with optional `schema_version` parameter
- Dispatches to Swagger 2.0 extraction when `schema_version$type == "swagger"`
- Maintains backward compatibility (defaults to OpenAPI 3.0 behavior)
- Non-breaking change for existing callers

**5. Preflight Endpoint Filtering**
- Added "preflight" to `ENDPOINT_PATTERNS_TO_EXCLUDE` (FILT-01)
- Filters out CORS preflight OPTIONS endpoints during schema preprocessing

## Task Execution Summary

| Task | Description | Commit | Status |
|------|-------------|--------|--------|
| 1 | Add preflight exclusion pattern | 2ff3b1c | ✓ Complete |
| 2 | Add version detection and Swagger 2.0 extraction functions | 5a727ad | ✓ Complete |
| 3 | Update extract_body_properties for version-aware dispatch | 1bc934e | ✓ Complete |

**All tasks completed successfully with atomic commits.**

## Technical Details

### Swagger 2.0 vs OpenAPI 3.0 Body Extraction

**OpenAPI 3.0:**
```
operation:
  requestBody:
    content:
      application/json:
        schema:
          $ref: "#/components/schemas/SchemaName"
```

**Swagger 2.0:**
```
operation:
  parameters:
    - in: "body"
      schema:
        $ref: "#/definitions/SchemaName"
```

### Function Signatures

```r
detect_schema_version(schema)
# Returns: list(version = "2.0", type = "swagger"|"openapi"|"unknown")

extract_swagger2_body_schema(parameters, definitions)
# Returns: list(type = "object"|"array"|"string", properties = list(...))

resolve_swagger2_definition_ref(ref, definitions)
# Returns: schema_def or NULL

extract_body_properties(request_body, components, schema_version = NULL)
# Returns: list(type = ..., properties = list(...))
```

### Validation Warnings

The Swagger 2.0 extraction validates spec constraints and warns on violations:

- **Multiple body parameters:** Uses first, warns user
- **Body + formData mixing:** Uses body, warns user (spec violation)

These warnings use `cli::cli_alert_warning()` for consistent logging.

## Deviations from Plan

None - plan executed exactly as written.

## Testing & Verification

**Verification script created:** `dev/endpoint_eval/verify_07-01.R`

Manual verification confirms:
- ✓ FILT-01: Preflight pattern added to exclusion list
- ✓ VERS-01: Swagger 2.0 schemas detected correctly
- ✓ VERS-02: OpenAPI 3.0 schemas detected correctly
- ✓ BODY-01: Swagger 2.0 body parameters extracted from parameters[] array
- ✓ BODY-03: `#/definitions/` references resolved correctly
- ✓ BODY-04: Inline object schemas (no $ref) extract properties directly
- ✓ BODY-05: Multiple body parameters trigger warning
- ✓ BODY-06: Body+formData mixing triggers warning

**Test coverage:**
- Version detection: Swagger 2.0, OpenAPI 3.0, unknown schemas
- Body extraction: AMOS batch_search endpoint (Swagger 2.0 with $ref)
- Backward compatibility: extract_body_properties() with/without schema_version

## Integration Points

**Upstream dependencies:**
- Existing `extract_body_properties()` for OpenAPI 3.0 logic
- `%||%` helper from 00_config.R
- `purrr::keep()`, `purrr::imap()` for functional operations
- `cli::cli_alert_warning()` for user-facing warnings

**Downstream consumers:**
- Phase 07 Plan 02 will use `detect_schema_version()` to identify schema type
- Phase 09 stub regeneration will test both extraction paths
- Future endpoint processing will dispatch based on schema version

## Commits

```
2ff3b1c chore(07-01): add preflight exclusion pattern
5a727ad feat(07-01): add version detection and Swagger 2.0 body extraction
1bc934e feat(07-01): add version-aware dispatch to extract_body_properties
```

**Total: 3 commits, 182 lines added, 2 lines modified**

## Next Phase Readiness

**Phase 07 Plan 02 blockers:** None

**What's next:**
- Plan 02: Fallback reference resolution (try #/definitions/, then #/components/schemas/)
- Plan 03: Integration testing with stub regeneration

**Known issues:** None

**Technical debt:** None

**Follow-up work:**
- Unit tests for version detection (deferred to v2 - TEST-01)
- Unit tests for Swagger 2.0 body extraction (deferred to v2 - TEST-02)

## Success Criteria Met

- [x] FILT-01: ENDPOINT_PATTERNS_TO_EXCLUDE contains "preflight"
- [x] VERS-01: detect_schema_version() returns type="swagger" for Swagger 2.0
- [x] VERS-02: detect_schema_version() returns type="openapi" for OpenAPI 3.0
- [x] BODY-01: extract_swagger2_body_schema() extracts from parameters[].in="body"
- [x] BODY-03: resolve_swagger2_definition_ref() resolves #/definitions/
- [x] BODY-04: Inline object schemas extract properties directly
- [x] BODY-05: Multiple body parameters trigger warning, first used
- [x] BODY-06: Body+formData mixing triggers warning

**All success criteria satisfied.**

---

*Completed: 2026-01-29 | Duration: 2.3 minutes | Status: ✓ Ready for Phase 07 Plan 02*
