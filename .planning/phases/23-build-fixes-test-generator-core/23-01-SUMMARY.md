---
phase: 23-build-fixes-test-generator-core
plan: 01
subsystem: package-infrastructure
tags: [build-fixes, licensing, imports, encoding, httr2-compat]
dependency-graph:
  requires: [PR-113-schema-updates]
  provides: [clean-description, valid-license, ascii-only-source, httr2-compat]
  affects: [build-process, r-cmd-check]
tech-stack:
  added: [MIT-license]
  patterns: [unicode-escapes, explicit-namespacing, httr2-status-checks]
key-files:
  created: [LICENSE, LICENSE.md]
  modified: [DESCRIPTION, R/extract_mol_formula.R, R/chemi_functional_use.R, R/util_classyfire.R, R/ct_chemical_msready_by-mass.R, R/ct_chemical_msready_search_by_mass.R]
decisions:
  - "Used MIT + file LICENSE per user decision"
  - "Replaced non-ASCII characters with \\uxxxx escapes for portability"
  - "Fixed httr2 compatibility using resp_status() instead of missing helper functions"
  - "Renamed body → request_body to avoid partial argument matching"
metrics:
  duration-minutes: 5.3
  tasks-completed: 3
  files-modified: 7
  completed-date: 2026-02-27
---

# Phase 23 Plan 01: Build Infrastructure Fixes Summary

**Merged open schema PR and fixed all non-generator BUILD issues for clean R CMD check baseline**

## Objective

Fix DESCRIPTION license and imports (BUILD-02, BUILD-07), non-ASCII characters (BUILD-03), import collisions (BUILD-04), httr2 compatibility (BUILD-05), and partial argument matches (BUILD-08) to establish a clean package infrastructure before touching the stub generator.

## Tasks Completed

### Task 1: Merge open PR and fix license + imports (BUILD-02, BUILD-07)
**Commit:** `b31c3bc`
**Files:** DESCRIPTION, LICENSE, LICENSE.md, NAMESPACE

1. Merged PR #113 (schema automation updates) into integration branch
2. Created LICENSE file with MIT license (year: 2026, copyright: Sean Thimons)
3. Created LICENSE.md with full MIT license text
4. Updated DESCRIPTION:
   - Replaced invalid placeholder with `License: MIT + file LICENSE`
   - Removed `ggplot2` from Imports (not used in R/ code)
   - Removed `janitor` from Imports (not used in R/ code)
   - Removed `testthat` from Imports, added to Suggests
   - Kept `scales` (verified usage)
5. Ran `devtools::document()` to regenerate NAMESPACE

**Verification:** DESCRIPTION has valid MIT license, ggplot2/janitor removed from Imports, testthat only in Suggests

### Task 2: Fix non-ASCII characters and import collision (BUILD-03, BUILD-04)
**Commit:** `c252151`
**Files:** R/extract_mol_formula.R, R/chemi_functional_use.R

1. Fixed BUILD-03 (Non-ASCII characters in extract_mol_formula.R):
   - Middle dot (·) → `\u00b7` (9 occurrences)
   - En dash (–) → `\u2013` (4 occurrences)
   - All instances in comments, strings, and regex patterns
2. Fixed BUILD-04 (Import collision):
   - Prefixed bare `flatten()` call with `jsonlite::` in chemi_functional_use.R
   - Prevents collision between jsonlite::flatten and purrr::flatten

**Verification:** Zero non-ASCII characters in R/ source files, no flatten import collision

### Task 3: Fix httr2 compatibility and partial argument match (BUILD-05, BUILD-08)
**Commit:** `b0dab47`
**Files:** R/util_classyfire.R, R/ct_chemical_msready_by-mass.R, R/ct_chemical_msready_search_by_mass.R

1. Fixed BUILD-05 (httr2 compatibility in util_classyfire.R):
   - Replaced `httr2::resp_is_transient(.x) || httr2::resp_status_class(.x) == "server"`
   - With equivalent logic: `status == 429 || status >= 500`
   - Uses `httr2::resp_status()` which exists in all httr2 versions
2. Fixed BUILD-08 (Partial argument match):
   - Renamed `body` variable to `request_body` in two msready functions
   - Prevents R's partial matching from matching `body =` to `body_type =`
   - Affects `ct_chemical_msready_by_mass` and `ct_chemical_msready_search_by_mass_bulk`

**Verification:** All files parse without errors, no httr2 function references to missing helpers, no partial match warnings

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

**Post-task checks:**
- ✅ All R/ files parse without errors
- ✅ DESCRIPTION has valid license field: `MIT + file LICENSE`
- ✅ LICENSE file exists at package root
- ✅ ggplot2, janitor removed from Imports
- ✅ testthat only in Suggests (via Config/testthat)
- ✅ R/extract_mol_formula.R has zero non-ASCII characters
- ✅ No import collision between jsonlite::flatten and purrr::flatten
- ✅ httr2 compatibility resolved (no references to resp_is_transient or resp_status_class)
- ✅ No partial argument match warnings for body/body_type

**Overall verification:**
```r
devtools::document()
# ℹ Updating ComptoxR documentation
# ℹ Loading ComptoxR
# [No import collision warnings]
# Writing 'extract_formulas.Rd'
```

## Self-Check: PASSED

**Created files verified:**
```bash
✅ FOUND: LICENSE
✅ FOUND: LICENSE.md
```

**Commits verified:**
```bash
✅ FOUND: b31c3bc (fix license and clean imports)
✅ FOUND: c252151 (fix non-ASCII chars and import collision)
✅ FOUND: b0dab47 (fix httr2 compatibility and partial argument match)
```

**Modified files verified:**
```bash
✅ FOUND: DESCRIPTION (License: MIT + file LICENSE)
✅ FOUND: R/extract_mol_formula.R (0 non-ASCII characters)
✅ FOUND: R/chemi_functional_use.R (jsonlite::flatten explicit)
✅ FOUND: R/util_classyfire.R (httr2 compat fixed)
✅ FOUND: R/ct_chemical_msready_by-mass.R (request_body rename)
✅ FOUND: R/ct_chemical_msready_search_by_mass.R (request_body rename)
```

## Impact

**Package infrastructure:**
- DESCRIPTION now has valid CRAN-compliant license
- All source files are pure ASCII (portable across systems)
- Import dependencies cleaned up (no unused packages)
- httr2 compatibility issues resolved for older/newer versions

**R CMD check readiness:**
- BUILD-02 (Imports cleanup) ✅ Fixed
- BUILD-03 (Non-ASCII) ✅ Fixed
- BUILD-04 (Import collision) ✅ Fixed
- BUILD-05 (httr2 compat) ✅ Fixed
- BUILD-07 (License) ✅ Fixed
- BUILD-08 (Partial match) ✅ Fixed

**Remaining BUILD issues (out of scope for this plan):**
- BUILD-01: Invalid syntax in chemi_arn_cats_bulk (generator bug, Wave 2)
- BUILD-06: Duplicate endpoint arguments (generator bug, Wave 2)
- Roxygen @param mismatches (Wave 3)

## Next Steps

1. Continue to Plan 02: Fix generator pipeline core (BUILD-01 syntax bugs)
2. Implement schema automation Items 2 & 3 (Plan 03)
3. Purge experimental stubs and regenerate with fixed generator (Plan 04)
4. Run full R CMD check to verify all BUILD issues resolved (Plan 05)

## Technical Notes

**Unicode escape patterns:**
- Middle dot `\u00b7` used for chemical formulas (e.g., "CuSO4 \u00b7 5H2O")
- En dash `\u2013` used for carbon ranges (e.g., "C9\u201312")

**httr2 compatibility approach:**
- Used Option B: Replace missing functions with equivalent logic
- Avoided bumping httr2 minimum version (maintains broader compatibility)
- Custom `is_transient_error()` helper already exists in z_generic_request.R

**Partial argument matching:**
- R allows abbreviated parameter names but CRAN flags this as bad practice
- Fixed by renaming local variables to avoid overlap with function parameters
- Alternative would be to use named list syntax: `do.call(generic_request, list(request_body = body))`

## Metrics

- **Duration:** 5.3 minutes
- **Tasks:** 3/3 completed
- **Commits:** 3 (one per task, atomic)
- **Files modified:** 7
- **Requirements satisfied:** BUILD-02, BUILD-03, BUILD-04, BUILD-05, BUILD-07, BUILD-08
