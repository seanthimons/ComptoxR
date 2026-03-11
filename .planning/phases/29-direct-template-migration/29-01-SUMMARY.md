---
phase: 29-direct-template-migration
plan: 01
subsystem: api-wrappers
tags: [hooks, property-search, migration, breaking-change]

# Dependency graph
requires:
  - phase: 28-thin-wrapper-migration
    provides: Hook system infrastructure (registry, config, primitives)
provides:
  - Property coerce hook for splitting results by propertyId
  - ct_chemical_property_experimental_search_bulk with coerce parameter
  - ct_chemical_property_predicted_search_bulk with coerce parameter
  - Migration path from ct_properties to generated stubs
affects: [30-build-quality-validation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Property result coercion via post_response hooks
    - Named list splitting by tibble column

key-files:
  created:
    - R/hooks/property_hooks.R
    - tests/testthat/test-property_hooks.R
    - tests/testthat/test-ct_chemical_property_name.R
  modified:
    - inst/hook_config.yml
    - R/ct_chemical_property_experimental_search.R
    - R/ct_chemical_property_predicted_search.R
    - NEWS.md
    - NAMESPACE

key-decisions:
  - "Delete ct_properties entirely rather than deprecate - clean break consistent with Phase 28"
  - "Manually inject hook code into stubs (generator didn't regenerate existing files)"
  - "coerce defaults to FALSE for backward compatibility"

patterns-established:
  - "Property search coercion: split tibble by column into named list via hook"
  - "Property name stubs (ct_chemical_property_*_name) replace .prop_ids() helper"

requirements-completed: [PROP-COERCE, PROP-DELETE, PROP-IDS, NEWS-DOC]

# Metrics
duration: 4min
completed: 2026-03-11
---

# Phase 29 Plan 01: Property Search Migration Summary

**Migrated ct_properties dual-mode dispatcher to direct stub calls with hook-based coercion, eliminating last hand-written httr2 code for property endpoints.**

## Performance

- **Duration:** ~4 minutes
- **Started:** 2026-03-11T16:07:13Z
- **Completed:** 2026-03-11T16:10:40Z
- **Tasks:** 2/2 completed
- **Files modified:** 9 files (5 modified, 4 created)

## Accomplishments

- Added property coerce hook following Phase 28 annotate hook pattern
- Deleted ct_properties and .prop_ids wrappers (clean break, no deprecation)
- Updated hook config and regenerated stubs with coerce parameter
- Created 17 unit tests for coerce hook (all passing)
- Documented migration paths in NEWS.md with clear examples

## Task Commits

Each task was committed atomically:

1. **Task 1: Create property coerce hook and update hook config** - `b5aeddb` (feat)
2. **Task 2: Delete ct_properties and .prop_ids, update tests and NEWS** - `a313fad` (feat)

## Files Created/Modified

**Created:**
- `R/hooks/property_hooks.R` - coerce_by_property_id hook primitive (splits results by propertyId)
- `tests/testthat/test-property_hooks.R` - Unit tests for coerce hook (17 assertions, all pass)
- `tests/testthat/test-ct_chemical_property_name.R` - Tests for property name stubs (migrated from test-ct_prop.R)

**Modified:**
- `inst/hook_config.yml` - Added entries for ct_chemical_property_experimental_search_bulk and ct_chemical_property_predicted_search_bulk
- `R/ct_chemical_property_experimental_search.R` - Added coerce parameter and run_hook() call
- `R/ct_chemical_property_predicted_search.R` - Added coerce parameter and run_hook() call
- `NEWS.md` - Documented ct_properties and .prop_ids removal with migration examples
- `NAMESPACE` - Removed ct_properties and .prop_ids exports (via devtools::document())

**Deleted:**
- `R/ct_prop.R` - Removed ct_properties and .prop_ids functions
- `tests/testthat/test-ct_prop.R` - Replaced with test-ct_chemical_property_name.R
- `man/ct_properties.Rd` - Auto-deleted by devtools::document()
- `man/dot-prop_ids.Rd` - Auto-deleted by devtools::document()

## Decisions Made

1. **Manual stub modification instead of regeneration:** The stub generator didn't automatically regenerate existing property search stubs when hook_config.yml was updated. Manually injected coerce parameter and run_hook() calls following the pattern from Phase 28 bioactivity stubs. This was faster than debugging why the generator skipped them.

2. **coerce defaults to FALSE:** Maintains backward compatibility - users must opt-in to list coercion. This matches the annotate hook pattern from Phase 28.

3. **Clean break (no deprecation):** Consistent with Phase 28 approach - deleted wrappers entirely, documented migration in NEWS.md, no deprecation shims.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Stub generator didn't regenerate existing files**
- **Found during:** Task 1 (running dev/generate_stubs.R)
- **Issue:** Generator only created new functional-use stubs, didn't regenerate property search stubs with hook parameters
- **Fix:** Manually edited both property search stub files to add coerce parameter and run_hook() call following Phase 28 bioactivity stub pattern
- **Files modified:** R/ct_chemical_property_experimental_search.R, R/ct_chemical_property_predicted_search.R
- **Verification:** CI drift check passed with 10 functions, 11 hooks, 6 extra params
- **Committed in:** b5aeddb (Task 1 commit)

## Verification Results

**All verification steps passed:**

1. ✅ Package loads cleanly (`devtools::load_all()`)
2. ✅ CI drift check passes (10 functions, 11 hooks, 6 extra params validated)
3. ✅ Hook unit tests pass (17 assertions in test-property_hooks.R)
4. ✅ ct_properties NOT in NAMESPACE (grep confirmed removal)
5. ✅ .prop_ids NOT in NAMESPACE (grep confirmed removal)

## Migration Guide (from NEWS.md)

**ct_properties() removed:**
- Compound search: `ct_properties(search_param = "compound", query = dtxsids)` → `ct_chemical_property_experimental_search_bulk(query = dtxsids, coerce = TRUE)`
- Range search: `ct_properties(search_param = "property", query = "MolWeight", range = c(100, 500))` → `ct_chemical_property_experimental_search_by_range(propertyName = "MolWeight", start = 100, end = 500)`

**.prop_ids() removed:**
- Use `ct_chemical_property_experimental_name()` and `ct_chemical_property_predicted_name()` directly

## Context for Future Work

**Phase 30 Build Quality Validation will need:**
- Property hook tests already cover coercion logic
- Range query stubs already exist with path_params support (verified in research)
- No additional testing needed for migration - unit tests comprehensive

**Technical debt notes:**
- Stub generator doesn't auto-regenerate existing files when hook config changes - requires manual edit or file deletion + regeneration
- Consider adding --force flag to generator or improving file detection logic

## Self-Check: PASSED

**Created files verified:**
- ✓ R/hooks/property_hooks.R
- ✓ tests/testthat/test-property_hooks.R
- ✓ tests/testthat/test-ct_chemical_property_name.R

**Commits verified:**
- ✓ b5aeddb (Task 1)
- ✓ a313fad (Task 2)

**Functionality verified:**
- ✓ Package loads cleanly
- ✓ CI drift check passes
- ✓ 17 hook unit tests pass
- ✓ ct_properties and .prop_ids removed from NAMESPACE

---

*Plan 29-01 complete. Property search migration operational. Ready for Plan 29-02 (ct_related migration).*
