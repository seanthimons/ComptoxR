---
phase: 26-pagination-tests-coverage-hardening
plan: 01
subsystem: testing-infrastructure
tags: [pagination, unit-tests, detection, registry, warnings]
dependency_graph:
  requires: [PAGINATION_REGISTRY, detect_pagination]
  provides: [test-pagination-detection.R, pagination-warning-system]
  affects: [dev/endpoint_eval/04_openapi_parser.R]
tech_stack:
  added: []
  patterns: [heuristic-validation, registry-coverage-testing]
key_files:
  created:
    - tests/testthat/test-pagination-detection.R
  modified:
    - dev/endpoint_eval/04_openapi_parser.R
decisions:
  - "Added heuristic check for 14 common pagination parameter names (page, pageNumber, offset, limit, skip, top, cursor, etc.)"
  - "Warning is informational only - still returns strategy 'none' to avoid breaking existing behavior"
  - "Dynamic schema test validates against real AMOS schema files, skips gracefully if schemas unavailable"
  - "Test suite covers all 7 PAGINATION_REGISTRY entries with real endpoint examples"
metrics:
  duration_minutes: 1.5
  tasks_completed: 2
  tests_added: 72
  files_modified: 2
  completion_date: 2026-03-01
---

# Phase 26 Plan 01: Pagination Detection Tests and Coverage Hardening Summary

**One-liner:** Comprehensive unit tests for all 7 PAGINATION_REGISTRY patterns plus heuristic warnings for unmatched pagination-like parameters.

## What Was Built

Created a comprehensive test suite for pagination pattern detection with full coverage of all 7 PAGINATION_REGISTRY entries, plus enhanced `detect_pagination()` with intelligent warnings for parameters that resemble pagination but don't match any registry entry.

**Key capabilities:**
- ✅ All 7 registry patterns tested with real endpoint examples
- ✅ Negative tests confirm no false positives for non-paginated endpoints
- ✅ Dynamic validation against actual AMOS schema files
- ✅ Warning system alerts developers to potential missing registry entries
- ✅ 72 passing tests covering all detection paths

## Implementation Details

### Task 1: Enhanced detect_pagination with Warning System

**File:** `dev/endpoint_eval/04_openapi_parser.R`

Added heuristic check before returning "No pagination detected":
- Defined 14 common pagination parameter names
- Checks if any endpoint params match pagination-like names
- Emits `cli::cli_warn()` with route and suspicious params
- Suggests adding new PAGINATION_REGISTRY entry
- Still returns `strategy = "none"` (behavior unchanged)

**Why this matters:** Helps identify endpoints that may need new registry entries (like the 5 keyset_pagination endpoints found during testing).

### Task 2: Comprehensive Test Suite

**File:** `tests/testthat/test-pagination-detection.R` (285 lines, 72 tests)

**Test structure:**
1. **Registry structure validation** (1 test, 7 assertions) - Verifies PAGINATION_REGISTRY has exactly 7 entries with expected names and required fields
2. **Pattern detection coverage** (7 tests) - Tests each registry entry with realistic endpoint data:
   - `offset_limit_path`: Route-based detection for AMOS pagination
   - `cursor_path`: Special case requiring "limit" in path + "cursor" in query
   - `page_number_query`: CTX hazard/exposure pageNumber
   - `offset_size_body`: Chemi search body parameters
   - `offset_size_query`: Common Chemistry query parameters
   - `page_size_query`: Chemi resolver classyfire
   - `page_items_query`: Chemi resolver pubchem
3. **Negative tests** (3 tests) - Confirms no false positives for:
   - Single-item GET endpoints
   - Bulk POST without pagination
   - Endpoints with no parameters
4. **Dynamic schema validation** (1 test) - Loads actual AMOS schema, verifies pagination endpoints are detected (skips if schemas unavailable)
5. **Warning behavior** (4 tests) - Validates warning system emits correct messages and still returns strategy "none"

**Sources dev/ dependencies:** Uses `source(here::here())` to load `00_config.R` and `04_openapi_parser.R` (not part of package namespace).

## Deviations from Plan

None - plan executed exactly as written.

## Testing Results

All 72 tests pass:
- ✅ Registry structure validated
- ✅ All 7 patterns correctly detected
- ✅ Negative tests confirm no false positives
- ✅ Dynamic schema test found 11 pagination routes in AMOS schema
- ✅ Warning system works as expected

**Interesting finding:** 5 AMOS endpoints emit warnings during dynamic schema test:
- `/api/amos/analytical_qc_keyset_pagination/{limit}`
- `/api/amos/fact_sheet_keyset_pagination/{limit}`
- `/api/amos/method_keyset_pagination/{limit}`
- `/api/amos/product_declaration_keyset_pagination/{limit}`
- `/api/amos/safety_data_sheet_keyset_pagination/{limit}`

These have "limit" in path but no "cursor" in query (unlike `similar_structures_keyset_pagination`). May need separate registry entry or are incomplete endpoints.

## Files Changed

| File | Lines | Change | Purpose |
|------|-------|--------|---------|
| `dev/endpoint_eval/04_openapi_parser.R` | +18 | Modified | Added heuristic warning for unmatched pagination-like params |
| `tests/testthat/test-pagination-detection.R` | +285 | Created | Comprehensive pagination detection test suite |

## Commits

| Hash | Message | Files |
|------|---------|-------|
| `f56c728` | feat(26-01): add warning for unmatched pagination-like parameters | dev/endpoint_eval/04_openapi_parser.R |
| `656d3f1` | test(26-01): add comprehensive pagination detection tests | tests/testthat/test-pagination-detection.R |

## Impact

**Before:**
- No tests for `detect_pagination()` function
- No way to identify potential missing registry entries
- Registry coverage unknown

**After:**
- 72 tests ensure all 7 patterns work correctly
- Warning system alerts to potential gaps (found 5 keyset_pagination variants)
- Negative tests prevent false positives
- Dynamic schema validation confirms real-world accuracy

**Requirement fulfilled:** PAG-20 (All 7 PAGINATION_REGISTRY patterns correctly detected from real schema data)

## Next Steps

Plan 02 will add regression tests for existing endpoint test files to ensure they continue working with pagination detection integrated into the schema parsing pipeline.

## Self-Check: PASSED

✅ **Created files exist:**
```bash
$ [ -f "tests/testthat/test-pagination-detection.R" ] && echo "FOUND: tests/testthat/test-pagination-detection.R" || echo "MISSING"
FOUND: tests/testthat/test-pagination-detection.R
```

✅ **Modified files exist:**
```bash
$ [ -f "dev/endpoint_eval/04_openapi_parser.R" ] && echo "FOUND: dev/endpoint_eval/04_openapi_parser.R" || echo "MISSING"
FOUND: dev/endpoint_eval/04_openapi_parser.R
```

✅ **Commits exist:**
```bash
$ git log --oneline --all | grep -q "f56c728" && echo "FOUND: f56c728" || echo "MISSING: f56c728"
FOUND: f56c728
$ git log --oneline --all | grep -q "656d3f1" && echo "FOUND: 656d3f1" || echo "MISSING: 656d3f1"
FOUND: 656d3f1
```

✅ **Tests pass:**
```bash
$ Rscript -e "testthat::test_file('tests/testthat/test-pagination-detection.R')"
[ FAIL 0 | WARN 5 | SKIP 0 | PASS 72 ]
```
(5 warnings are expected from dynamic schema test - they demonstrate the warning system works)

All verification checks passed.
