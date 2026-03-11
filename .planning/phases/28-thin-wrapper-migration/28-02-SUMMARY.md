---
phase: 28-thin-wrapper-migration
plan: 02
subsystem: hook-system
tags: [hooks, primitives, testing, unit-tests]
dependency_graph:
  requires:
    - HOOK-28-01  # Hook registry and dispatcher
    - HOOK-28-02  # YAML configuration system
  provides:
    - HOOK-28-03  # Hook primitive functions
    - HOOK-28-04  # Hook primitive unit tests
  affects:
    - stub-generation-pipeline
tech_stack:
  added: []
  patterns:
    - Pure function hooks (input data -> transformed data)
    - Hand-crafted mock data for testing (no VCR)
    - local_mocked_bindings for testing hooks that call other package functions
key_files:
  created:
    - R/hooks/validation_hooks.R         # Pre-request validation hooks
    - R/hooks/list_hooks.R                # Chemical list operation hooks
    - R/hooks/bioactivity_hooks.R         # Bioactivity data hooks
    - R/hooks/compound_hooks.R            # Compound hooks (placeholder)
    - tests/testthat/test-hook_primitives.R  # Unit tests for all hooks
  modified: []
decisions:
  - title: "Use toupper() instead of stringr for simple case conversion"
    rationale: "No external dependency needed for simple uppercase operation"
    alternatives: ["stringr::str_to_upper()"]
  - title: "Source hook files in tests rather than export functions"
    rationale: "Hooks are internal (@noRd) and don't need to be part of public API"
    alternatives: ["Export hooks with @export", "Create test helper"]
requirements_completed:
  - HOOK-28-03
  - HOOK-28-04
metrics:
  duration_minutes: 3
  tasks_completed: 2
  commits: 2
  files_created: 5
  files_modified: 0
  test_assertions: 31
  completed_date: "2026-03-11"
---

# Phase 28 Plan 02: Hook Primitives Implementation

**One-liner:** Implemented 6 hook primitive functions (validation, list operations, bioactivity annotation) with 31 unit test assertions using hand-crafted mock data and local_mocked_bindings.

## Overview

Created all hook primitive functions referenced in inst/hook_config.yml and comprehensive unit tests that verify each hook in isolation. These building blocks enable declarative customization of generated API wrapper functions through the hook registry established in 28-01.

## Tasks Completed

### Task 1: Create hook primitive functions
**Status:** ✅ Complete
**Commit:** cca866b

Created R/hooks/ directory with 4 hook files implementing 6 primitives:

**R/hooks/validation_hooks.R:**
- `validate_similarity(data)`: Pre-request hook that validates similarity parameter is numeric and between 0-1. Uses cli::cli_abort() for errors.

**R/hooks/list_hooks.R:**
- `uppercase_query(data)`: Converts query to uppercase (API expects uppercase list names)
- `extract_dtxsids_if_requested(data)`: Post-response hook that extracts DTXSIDs from list results, handles duplicate names, splits comma-separated strings, deduplicates
- `lists_all_transform(data)`: Transform hook for ct_lists_all that wraps ct_chemical_list_all with projection/coerce logic
- `format_compound_list_result(data)`: Post-response hook that formats compound-in-list results with CLI messages

**R/hooks/bioactivity_hooks.R:**
- `annotate_assay_if_requested(data)`: Post-response hook that joins assay annotations via ct_bioactivity_assay() when annotate=TRUE

**R/hooks/compound_hooks.R:**
- Placeholder file for future compound-related hooks

**Key implementation details:**
- All hooks follow contract: receive list(params=..., result=...), return transformed data
- Pre-request hooks don't have $result yet, only $params
- Transform hooks return final user-facing object (replace default parse)
- Used toupper() instead of stringr for simple case conversion (no extra dependency)

**Verification:** All hook files parse without syntax errors

### Task 2: Write unit tests for all hook primitives
**Status:** ✅ Complete
**Commit:** 738ce0c

Created tests/testthat/test-hook_primitives.R with 31 test assertions covering:

**validate_similarity (3 tests):**
- Rejects non-numeric input (cli_abort)
- Rejects out-of-range values (-0.1, 1.5)
- Accepts valid input (0.8) and passes data through unchanged

**uppercase_query (1 test):**
- Converts "prodwater" to "PRODWATER" in data$params$query

**extract_dtxsids_if_requested (3 tests):**
- Returns original result when extract_dtxsids=FALSE
- Splits comma-separated DTXSIDs when TRUE (single result)
- Handles duplicate names (multiple results), deduplicates

**lists_all_transform (2 tests):**
- Returns tibble with correct projection (mocked ct_chemical_list_all)
- Coerces dtxsids to vector when requested

**format_compound_list_result (2 tests):**
- Formats output with expected structure
- Handles no results (compact() removes NULL)

**annotate_assay_if_requested (2 tests):**
- Returns unchanged when annotate=FALSE
- Joins assay data when annotate=TRUE (mocked ct_bioactivity_assay)

**Testing approach:**
- All tests use hand-crafted mock data (no VCR cassettes)
- Used `local_mocked_bindings()` for hooks that call other package functions
- Sourced hook files directly in test setup (hooks are @noRd, not exported)

**Verification:** All 31 assertions pass via devtools::test(filter='hook_primitives')

## Deviations from Plan

None - plan executed exactly as written.

## Integration Points

**Upstream dependencies (from 28-01):**
- Hook registry loads config from inst/hook_config.yml
- run_hook() dispatcher executes registered hooks

**Downstream dependencies (28-03+):**
- Stub generator will inject extra_params from hook_config.yml into function signatures
- Generated stubs will call run_hook() at lifecycle points
- These hook functions will be invoked via match.fun() lookup

**YAML-to-function mapping verified:**
```
validate_similarity          -> R/hooks/validation_hooks.R
uppercase_query              -> R/hooks/list_hooks.R
extract_dtxsids_if_requested -> R/hooks/list_hooks.R
lists_all_transform          -> R/hooks/list_hooks.R
format_compound_list_result  -> R/hooks/list_hooks.R
annotate_assay_if_requested  -> R/hooks/bioactivity_hooks.R
```

## Testing Strategy

**Unit tests (31 assertions):**
- Hook functions tested in isolation with mock data
- No API calls or VCR cassettes required
- Each hook has 2+ test cases (happy path + edge cases)
- Mocked dependencies (ct_chemical_list_all, ct_bioactivity_assay) return small hand-crafted tibbles

**Combined hook system tests:**
- 42 total assertions (11 registry + 31 primitives)
- All pass via devtools::test(filter='hook')

**Not yet tested:** Integration with generated stubs (deferred to plans that generate and use stubs)

## Known Limitations

1. **Compound hooks placeholder:** R/hooks/compound_hooks.R is empty - hooks will be added as needed for compound operations
2. **No hook debugging utilities:** Could add dry-run or logging modes for troubleshooting hook chains
3. **No hook composition tests:** Only tested individual hooks, not chains (will be covered by integration tests)

These are intentional - this plan provides the primitive building blocks, subsequent plans will handle composition and integration.

## Success Criteria Verification

- [x] All tasks executed (2/2)
- [x] Each task committed individually (cca866b, 738ce0c)
- [x] All hook primitive tests pass (31/31 assertions)
- [x] All hooks referenced in inst/hook_config.yml exist in R/hooks/
- [x] devtools::document() runs clean
- [x] devtools::test(filter='hook') passes all registry + primitive tests (42 assertions)
- [x] Hook functions are pure (input -> output, no global state mutation)

## Files Changed

```
R/hooks/validation_hooks.R              | 34 +++++++++++ (new)
R/hooks/list_hooks.R                    | 123 ++++++++++++++++++++++++ (new)
R/hooks/bioactivity_hooks.R             | 21 +++++ (new)
R/hooks/compound_hooks.R                | 3 ++ (new)
tests/testthat/test-hook_primitives.R   | 227 +++++++++++++++++++++++++++++++ (new)
```

Total: 5 files created, 408 lines added

## Self-Check: PASSED

**Files created:**
- ✅ R/hooks/validation_hooks.R exists
- ✅ R/hooks/list_hooks.R exists
- ✅ R/hooks/bioactivity_hooks.R exists
- ✅ R/hooks/compound_hooks.R exists
- ✅ tests/testthat/test-hook_primitives.R exists

**Hook functions exist:**
- ✅ validate_similarity (validation_hooks.R)
- ✅ uppercase_query (list_hooks.R)
- ✅ extract_dtxsids_if_requested (list_hooks.R)
- ✅ lists_all_transform (list_hooks.R)
- ✅ format_compound_list_result (list_hooks.R)
- ✅ annotate_assay_if_requested (bioactivity_hooks.R)

**Commits exist:**
- ✅ cca866b: feat(28-02): create hook primitive functions
- ✅ 738ce0c: test(28-02): add unit tests for hook primitives

**Tests pass:**
- ✅ 31 test assertions passing (hook primitives)
- ✅ 42 total assertions passing (registry + primitives)
- ✅ No test failures, warnings, or skips

**Package builds:**
- ✅ devtools::document() succeeds
- ✅ All hook files parse without syntax errors

All deliverables verified and functional. Ready for 28-03 (stub generation integration).
