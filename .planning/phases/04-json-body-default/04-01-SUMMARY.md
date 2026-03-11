---
phase: 04
plan: 01
subsystem: stub-generation
tags:
  - body-type
  - json-encoding
  - raw-text
  - api
dependency_graph:
  requires:
    - 03-01 (RAW-TEXT-01 decision)
  provides:
    - Corrected stub generation for string_array body types
    - Endpoint-specific raw text detection
  affects:
    - Future function regeneration will produce correct body encoding
tech_stack:
  added: []
  patterns:
    - Endpoint-specific body type detection
key_files:
  created: []
  modified:
    - dev/endpoint_eval/07_stub_generation.R
decisions:
  - id: STUB-ARRAY-01
    context: string_array body type handling
    decision: Pass query directly to generic_request() for JSON encoding
  - id: STUB-RAW-01
    context: Raw text body detection
    decision: Only /chemical/search/equal/ POST triggers body_type = "raw_text"
metrics:
  duration: ~1 minute
  completed: 2026-01-27
---

# Phase 4 Plan 01: JSON Body Default Summary

**One-liner:** Fixed stub generation to use JSON encoding for string_array bodies, with endpoint-specific raw text handling only for /chemical/search/equal/

## What Was Built

### Task 1: Fix string_array body type handling

**Changed:** `dev/endpoint_eval/07_stub_generation.R`

The stub generation logic was incorrectly applying newline collapsing (`paste(query, collapse = "\n")`) to ALL string_array body types. This was a workaround that was too broad.

**Before (lines 457-474):**
```r
if (body_schema_type == "string_array") {
  body_string <- paste(query, collapse = "\n")
  # ... generated code with body_string ...
}
```

**After:**
```r
if (body_schema_type == "string_array") {
  # Array body: pass directly, generic_request() handles JSON encoding
  fn_body <- glue::glue('
{fn} <- function(query) {{
  result <- generic_request(
    query = query,
    endpoint = "{endpoint}",
    method = "{method}",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  return(result)
}}
')
}
```

### Task 2: Endpoint-specific raw text detection

**Added:** Endpoint-specific check to `is_raw_text_body` condition (lines 386-391)

**Before:**
```r
is_raw_text_body <- (
  body_schema_type == "string" &&
  toupper(method) == "POST" &&
  wrapper_fn == "generic_request"
)
```

**After:**
```r
is_raw_text_body <- (
  body_schema_type == "string" &&
  toupper(method) == "POST" &&
  wrapper_fn == "generic_request" &&
  (endpoint == "chemical/search/equal/" || grepl("chemical/search/equal/$", endpoint))
)
```

### Documentation Added

Added comprehensive comment block explaining the body type handling logic:
- References decision RAW-TEXT-01 from Phase 3
- Explains why only `/chemical/search/equal/` uses raw text
- Documents that all other endpoints use JSON encoding

## Key Decisions Made

| ID | Decision | Rationale |
|----|----------|-----------|
| STUB-ARRAY-01 | Pass query directly for string_array | generic_request() already handles JSON encoding via jsonlite::toJSON |
| STUB-RAW-01 | Endpoint-specific raw text check | Only one endpoint in entire API requires raw text body |

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Hash | Message | Files |
|------|---------|-------|
| 15cde53 | fix(04-01): correct string_array body type handling in stub generation | dev/endpoint_eval/07_stub_generation.R |

## Verification Results

1. `paste(query, collapse` count = 0 (removed)
2. `endpoint == "chemical/search/equal/"` check present with trailing slash
3. `string_array` code path generates direct `query = query`
4. Documentation comment "Body Type Handling" exists

## Impact

- **Immediate:** Stub generation now produces correct body encoding
- **Next step:** Regenerate functions to apply the fix (Phase 4 Plan 02)
- **Long-term:** New API wrapper functions will correctly use JSON encoding for bulk requests

## Next Phase Readiness

Ready for 04-02 (function regeneration) with no blockers.
