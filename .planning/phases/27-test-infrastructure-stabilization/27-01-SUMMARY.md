---
phase: 27-test-infrastructure-stabilization
plan: 01
subsystem: package-core
tags: [namespace, imports, deprecation-warnings]
dependency_graph:
  requires: []
  provides: [warning-free-package-load]
  affects: [all-r-functions]
tech_stack:
  added: []
  patterns: [selective-importFrom]
key_files:
  created: []
  modified:
    - R/ComptoxR-package.R
    - NAMESPACE
decisions:
  - "Migrated from blanket @import to selective @importFrom for purrr and jsonlite"
  - "Kept other blanket @import declarations (dplyr, httr2, cli, stringr, tidyr) unchanged as they are not causing deprecation warnings and are out of scope"
metrics:
  duration_seconds: 97
  tasks_completed: 1
  files_modified: 2
  commits: 1
  completed_date: "2026-03-09"
---

# Phase 27 Plan 01: Selective Import Declarations

**One-liner:** Replace blanket purrr/jsonlite imports with selective @importFrom declarations, eliminating purrr::flatten deprecation warnings on package load.

## What Was Built

Eliminated the purrr::flatten deprecation warning that appeared every time the package loaded by converting blanket `@import purrr` and `@import jsonlite` declarations to selective `@importFrom` declarations.

### Changes Made

1. **Audited purrr usage** across all R/ files, identifying 11 functions actually used:
   - map, map2, map_chr, map_lgl
   - imap
   - pluck
   - set_names
   - compact
   - keep
   - list_rbind
   - list_flatten

2. **Audited jsonlite usage**, identifying 3 functions:
   - fromJSON
   - flatten (used in chemi_functional_use.R)
   - write_json

3. **Updated R/ComptoxR-package.R**:
   - Replaced `#' @import purrr` with `#' @importFrom purrr map map2 map_chr map_lgl imap pluck set_names compact keep list_rbind list_flatten`
   - Replaced `#' @import jsonlite` with `#' @importFrom jsonlite fromJSON flatten write_json`
   - Left other @import declarations unchanged (dplyr, httr2, cli, stringr, tidyr)

4. **Regenerated NAMESPACE** via `devtools::document()`

5. **Verified**:
   - NAMESPACE contains no `import(purrr)` or `import(jsonlite)` entries
   - NAMESPACE has correct `importFrom(purrr,...)` and `importFrom(jsonlite,...)` entries
   - Package loads without deprecation warnings
   - All bare function calls (like `map()`) still resolve correctly

## Verification Results

**Automated verification:**
```r
devtools::load_all()
# ℹ Loading ComptoxR
# [No deprecation warnings]

packageVersion('ComptoxR')
# [1] '1.4.0'
```

**NAMESPACE inspection:**
- ✅ No `import(purrr)` or `import(jsonlite)`
- ✅ 11 selective `importFrom(purrr,...)` entries
- ✅ 3 selective `importFrom(jsonlite,...)` entries

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Hash    | Message                                                          |
| ------- | ---------------------------------------------------------------- |
| e86b18c | fix(27-01): replace blanket purrr/jsonlite imports with selective importFrom |

## Files Modified

- **R/ComptoxR-package.R**: Changed @import to @importFrom for purrr and jsonlite
- **NAMESPACE**: Regenerated with selective imports (no longer has blanket imports)

## Success Criteria Met

- ✅ NAMESPACE contains selective importFrom for purrr and jsonlite
- ✅ Package loads without purrr::flatten deprecation warning
- ✅ No missing imports (all bare function calls resolve correctly)

## Impact

This fix removes a mechanical blocker for reliable test execution. The purrr::flatten deprecation warning was triggering on every package load, polluting test output and making it harder to identify real issues.

The package now loads cleanly without warnings, enabling:
1. Clean test output (no deprecation noise)
2. Reliable CI/CD pipeline execution
3. Better developer experience (no confusing warnings)

All existing functionality preserved - bare function calls like `map()`, `pluck()`, `fromJSON()` continue to work because `@importFrom` makes them available in the package namespace.

## Self-Check: PASSED

Files verified:
- ✅ FOUND: R/ComptoxR-package.R
- ✅ FOUND: NAMESPACE

Commits verified:
- ✅ FOUND: e86b18c
