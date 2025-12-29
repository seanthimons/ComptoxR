# Refactor Status: ct_list and ct_lists_all

## Summary

Successfully refactored **ct_list** and **ct_lists_all** to use the enhanced `generic_request` template with the new `tidy` parameter and static endpoint support.

---

## Key Enhancements Made to `generic_request`

### 1. Added `tidy` Parameter (Previously completed)
- **`tidy = TRUE`** (default): Returns tibble
- **`tidy = FALSE`**: Returns cleaned list structure

### 2. Added Static Endpoint Support (NEW)
- **`batch_limit = 0`**: Special flag for static endpoints (no query parameter needed)
- Bypasses query validation and path appending
- Only adds named arguments as query parameters

**Location**: R/z_generic_request.R:42-46, 115-119

---

## Refactored Functions

### 1. ct_list (R/ct_list.R:15)

**Before**: 56 lines of custom httr2 with `resps_successes()`

**After**: 42 lines using `generic_request` with `tidy=FALSE`

```r
# Now uses generic_request template
dat <- generic_request(
  query = stringr::str_to_upper(list_name),
  endpoint = "chemical/list/search/by-name/",
  method = "GET",
  batch_limit = 1,
  tidy = FALSE,  # Returns list for flexible output
  projection = 'chemicallistwithdtxsids'
)
```

**Benefits**:
- Automatic batching support
- Built-in debug/verbose modes
- Consistent error handling
- Authentication handling
- 25% code reduction

---

### 2. ct_lists_all (R/ct_lists_all.R:11)

**Before**: 67 lines of custom httr2 with hardcoded URL

**After**: 60 lines using `generic_request` with `batch_limit=0`

```r
# Uses new static endpoint support
df <- generic_request(
  query = NULL,  # No query needed
  endpoint = "chemical/list/",
  method = "GET",
  batch_limit = 0,  # Static endpoint flag
  server = "https://api-ccte.epa.gov",
  tidy = TRUE,
  projection = projection
)
```

**Benefits**:
- Leverages generic template for static endpoint
- Consistent with rest of codebase
- Built-in debug/verbose modes
- Cleaner URL construction

---

## Current Refactoring Status

### Functions Using Generic Templates: **14 of 35** (40%)

**Using `generic_request` (9):**
1. ct_hazard
2. ct_cancer
3. ct_env_fate
4. ct_genotox
5. ct_skin_eye
6. ct_similar
7. **ct_compound_in_list** ← with `tidy=FALSE`
8. **ct_list** ← NEW!
9. **ct_lists_all** ← NEW! (with `batch_limit=0`)

**Using `generic_chemi_request` (5):**
1. chemi_toxprint
2. chemi_safety
3. chemi_hazard
4. chemi_rq
5. chemi_classyfire

---

## Technical Details

### batch_limit Modes in generic_request

| batch_limit | Mode | Behavior | Use Case |
|-------------|------|----------|----------|
| `0` | Static endpoint | No query appending; only query params | ct_lists_all |
| `1` | Path-based GET | Append query to URL path | ct_compound_in_list, ct_list |
| `>1` | Bulk GET | Add as `search=` query parameter | Bulk searches |
| `>1` | POST | JSON body with batching | ct_hazard, ct_cancer, etc. |

### tidy Parameter Usage

| tidy | Output | Use Case |
|------|--------|----------|
| `TRUE` | Tibble (data frame) | Standard data analysis (most ct_* functions) |
| `FALSE` | Cleaned list | Custom post-processing needed (ct_compound_in_list, ct_list) |

---

## Next Refactoring Candidates

With `tidy=FALSE` and `batch_limit=0` support, these functions are now easier to refactor:

### High Priority:
1. **ct_related** - Complex nested list processing; could use `generic_request(..., tidy=FALSE, batch_limit=1)`
2. **ct_bioactivity** - Dynamic endpoint; could use `generic_request(..., batch_limit=1)`
3. **ct_expo** - Multiple endpoints; might benefit from template approach

### Medium Priority:
4. **chemi_predict** - Multiple output formats; could use `generic_chemi_request(..., tidy=FALSE)`
5. **chemi_cluster** - Matrix output; could use `generic_chemi_request(..., tidy=FALSE)`
6. **chemi_functional_use** - Sequential requests; could use template

---

## Impact Summary

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Functions using generic templates | 12 | 14 | +2 |
| Generic request capabilities | 3 modes | 4 modes | +static endpoints |
| ct_list LOC | 56 | 42 | -25% |
| ct_lists_all LOC | 67 | 60 | -10% |
| Functions with custom httr2 | 23 | 21 | -2 |
| **Total refactoring completion** | **34%** | **40%** | **+6%** |

---

## Files Modified

```
M R/ct_classify.R          # Classifier loading logic
M R/ct_compound_in_list.R  # Now uses generic_request with tidy=FALSE
M R/ct_descriptors.R       # httr → httr2
M R/ct_file.R              # httr → httr2
M R/ct_list.R              # Now uses generic_request with tidy=FALSE ✓
M R/ct_lists_all.R         # Now uses generic_request with batch_limit=0 ✓
M R/ct_test.R              # httr → httr2 (ct_test & ct_opera)
M R/z_generic_request.R    # Added tidy param + static endpoint support ✓
```

---

## Conclusion

The `generic_request` template is now more powerful and flexible:

1. **`tidy` parameter**: Enables list output for functions needing custom post-processing
2. **`batch_limit=0`**: Supports static endpoints without query parameters
3. **40% refactoring completion**: 14 of 35 functions now use generic templates

These enhancements open up ~5-8 more functions for refactoring, reducing code duplication and improving maintainability across the CompToxR package.
