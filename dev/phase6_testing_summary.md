# Phase 6 Testing Summary

## Test Execution

### What Was Done
1. **Modified `chemi_endpoint_eval.R`**: Changed `overwrite = FALSE` to `overwrite = TRUE`
2. **Deleted existing stubs**: Removed hazard and resolver R files to force regeneration
3. **Ran `chemi_endpoint_eval.R`**: Generated new stubs for all chemi endpoints
4. **Added debug output**: To `extract_query_params_with_refs` function

### Results

#### 1. Schema Parsing ✅
- All chemi schemas parsed successfully
- Hazard schema: 2 endpoints parsed
- Resolver schema: 25 endpoints parsed

#### 2. Query Parameter Extraction ✅
- `extract_query_params_with_refs()` function working correctly
- Debug output shows flattened parameters are returned:
  - Example: `DEBUG: query_names = files[], request.filesInfo, request.options`
  - Example: `DEBUG: query_meta names = files[], request.filesInfo, request.options`
- Binary arrays are correctly excluded (rejected)
- Non-binary arrays are supported

#### 3. Stub Generation ⚠️ ISSUE FOUND
- Stub files were generated but **do not contain flattened query parameters**
- Expected: `chemi_resolver_universalharvest(request, request.filesInfo, request.options, ...)`
- Actual: `chemi_resolver_universalharvest(request)` - **Only one parameter!**

### Issues Identified

#### Issue 1: `build_function_stub()` doesn't use flattened query parameters

**Location**: `dev/endpoint_eval_utils.R:2363-2367`

**Problem**: For `generic_chemi_request` wrapper:
- `{query_param_info$params_code}` is NOT used
- Only uses `{primary_param}` and `{combined_calls}`
- `{combined_calls}` is empty for many endpoints

**Evidence**:
```r
# Line 2363-2367
fn_body <- glue::glue('
{fn} <- function({fn_signature}){
{query_param_info$params_code}  result <- generic_chemi_request(
    query = {primary_param},
    endpoint = "{endpoint}"{combined_calls},
    tidy = FALSE
  )
```

**Impact**: Flattened query parameters from Phase 5 are not included in generated function signatures

#### Issue 2: `query_param_info$params_call` doesn't contain flattened params

**Location**: `dev/endpoint_eval_utils.R:1560-1571`

**Problem**: For `strategy == "options"`:
```r
params_call = ",\n    options = options"
```

This should generate:
```r
options[['files[]']] <- files[]
options[['request.filesInfo']] <- request.filesInfo
options[['request.options']] <- request.options
```

But `parse_function_params()` only generates code if params exist, and the logic may not be triggering correctly.

#### Issue 3: Stub files don't match Phase 5 functionality

**Example**: `R/chemi_resolver_universalharvest.R`
- Current signature: `chemi_resolver_universalharvest(request)`
- Expected signature (with Phase 5):
  ```r
  chemi_resolver_universalharvest(
    request,
    request.filesInfo = NULL,
    request.options = NULL,
    ...
  )
  ```

### What's Working

✅ **Phase 4 (`request_type` classification)**:
- `request_type` column populated in spec tibble
- `build_function_stub()` uses `request_type` for endpoint classification
- Backward compatibility maintained

✅ **Phase 5 (`extract_query_params_with_refs` function)**:
- Function correctly resolves $ref schemas
- Function flattens object properties with dot notation
- Function rejects binary arrays (e.g., `files[]`)
- Function supports non-binary arrays
- Function preserves original parameter name as prefix
- Full metadata extraction (name, type, format, description, enum, default, required, example)

✅ **Integration**:
- `openapi_to_spec()` calls `extract_query_params_with_refs()`
- Query parameters are resolved and flattened
- Debug output confirms functionality works

### What's Not Working

❌ **Stub Generation with Phase 5 query parameters**:
- Flattened query parameters are extracted but NOT included in generated stubs
- Generated stubs only use `primary_param` (first query parameter)
- Additional flattened parameters (e.g., `request.filesInfo`, `request.options`) are lost

### Root Cause

The issue is NOT in `extract_query_params_with_refs()` - this function works correctly.

The issue is in `build_function_stub()` and/or `render_endpoint_stubs()`:
- Flattened query parameters exist in `query_param_info$params_code`
- But `generic_chemi_request` wrapper is not using `params_code`
- Only uses `primary_param` and `combined_calls`

### Recommendations

1. **Update `build_function_stub()`**: Ensure flattened query parameters are used in generated stubs
2. **Update `generic_chemi_request` wrapper**: Use `options` parameter to pass flattened query params
3. **Test with actual API calls**: Verify generated functions work with the EPA CompTox API
4. **Review `param_strategy`**: Ensure "options" strategy works correctly with flattened parameters

### Test Status

- ✅ Phase 4: Implemented and integrated
- ✅ Phase 5: Implemented and working (function works)
- ⚠️ Phase 6: Partial - schema parsing works, stub generation incomplete
- ❌ Integration: Generated stubs don't include Phase 5 functionality
