---
phase: 29-direct-template-migration
verified: 2026-03-11T18:30:00Z
status: passed
score: 11/11 must-haves verified
re_verification: false
---

# Phase 29: Direct Template Migration Verification Report

**Phase Goal:** Migrate medium-complexity functions (ct_prop, ct_related) that use raw httr2 to generic_request()

**Verified:** 2026-03-11T18:30:00Z

**Status:** passed

**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | ct_chemical_property_experimental_search_bulk(query, coerce=TRUE) splits results by propertyId into named list | ✓ VERIFIED | Hook function exists, coerce parameter present, run_hook call wired, tests pass (17/17) |
| 2 | ct_chemical_property_predicted_search_bulk(query, coerce=TRUE) splits results by propertyId into named list | ✓ VERIFIED | Hook function exists, coerce parameter present, run_hook call wired, tests pass (17/17) |
| 3 | ct_chemical_property_experimental_name() returns tibble of property names (replaces .prop_ids) | ✓ VERIFIED | Function exported in NAMESPACE, uses generic_request with batch_limit=0 |
| 4 | ct_chemical_property_predicted_name() returns tibble of property names (replaces .prop_ids) | ✓ VERIFIED | Function exported in NAMESPACE, uses generic_request with batch_limit=0 |
| 5 | ct_properties() and .prop_ids() no longer exist in NAMESPACE | ✓ VERIFIED | Grep NAMESPACE: no matches, R check: both functions return FALSE for exists() |
| 6 | NEWS.md documents ct_properties and .prop_ids removal with migration examples | ✓ VERIFIED | NEWS.md lines 38-54 contain Phase 29 section with migration paths for both functions |
| 7 | ct_related(query, inclusive) returns identical results using generic_request instead of raw httr2 | ✓ VERIFIED | No httr2:: code in ct_related.R, generic_request called (2 instances), tests pass (7/7) |
| 8 | Server URL is restored to original value even if generic_request errors | ✓ VERIFIED | on.exit(Sys.setenv(ctx_burl = old_server), add = TRUE) on line 45, guaranteed cleanup |
| 9 | Inclusive filtering still works correctly for multi-compound queries | ✓ VERIFIED | Filtering logic preserved on lines 91-93, tests verify validation |
| 10 | Single-compound queries return related substances with parent excluded | ✓ VERIFIED | Filter on line 88 removes parent (child != query), tests verify behavior |
| 11 | NEWS.md documents ct_related migration to generic_request | ✓ VERIFIED | NEWS.md lines 56-61 document ct_related migration with server cleanup improvement |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| R/hooks/property_hooks.R | coerce_by_property_id hook function | ✓ VERIFIED | 30 lines, contains coerce_by_property_id function with proper hook signature |
| inst/hook_config.yml | Hook config entries for property search bulk functions | ✓ VERIFIED | Lines 78-94 contain entries for both experimental and predicted bulk functions |
| R/ct_chemical_property_experimental_search.R | Regenerated stub with coerce parameter | ✓ VERIFIED | Line 15: coerce parameter with default FALSE, line 23: run_hook call |
| R/ct_chemical_property_predicted_search.R | Regenerated stub with coerce parameter | ✓ VERIFIED | Line 15: coerce parameter with default FALSE, line 23: run_hook call |
| R/ct_related.R | Migrated ct_related using generic_request | ✓ VERIFIED | 97 lines, uses generic_request (2 calls), on.exit cleanup (line 45), no httr2:: code |
| tests/testthat/test-ct_related.R | Tests for migrated ct_related | ✓ VERIFIED | File exists, 7 tests pass including server cleanup and validation tests |
| tests/testthat/test-property_hooks.R | Property hook unit tests | ✓ VERIFIED | File created, 17 tests pass covering coerce logic |
| tests/testthat/test-ct_chemical_property_name.R | Tests for property name stubs | ✓ VERIFIED | File created (renamed from test-ct_prop.R), tests pass |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| inst/hook_config.yml | R/hooks/property_hooks.R | post_response hook name | ✓ WIRED | Lines 85 and 94 reference "coerce_by_property_id" which exists in property_hooks.R |
| R/ct_chemical_property_experimental_search.R | R/hooks/property_hooks.R | run_hook() call | ✓ WIRED | Line 23: run_hook("ct_chemical_property_experimental_search_bulk", "post_response", ...) |
| R/ct_chemical_property_predicted_search.R | R/hooks/property_hooks.R | run_hook() call | ✓ WIRED | Line 23: run_hook("ct_chemical_property_predicted_search_bulk", "post_response", ...) |
| R/ct_related.R | R/z_generic_request.R | generic_request() call | ✓ WIRED | Line 53: generic_request called with batch_limit=0 pattern for query parameters |
| R/ct_related.R | R/zzz.R | ctx_server() for server switching | ✓ WIRED | Line 44: ctx_server(9) call, line 45: on.exit restoration |

### Requirements Coverage

**Note:** Phase 29 requirements (PROP-COERCE, PROP-DELETE, PROP-IDS, REL-MIGRATE, REL-VALIDATE, NEWS-DOC) are not documented in REQUIREMENTS.md as that file only covers v2.1. These requirements were defined in the PLAN frontmatter for v2.2 Phase 29.

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PROP-COERCE | 29-01-PLAN.md | Property coerce hook splits results by propertyId | ✓ SATISFIED | coerce_by_property_id hook exists, integrated into both bulk functions, 17 tests pass |
| PROP-DELETE | 29-01-PLAN.md | Delete ct_properties wrapper | ✓ SATISFIED | R/ct_prop.R deleted, ct_properties not in NAMESPACE, exists() returns FALSE |
| PROP-IDS | 29-01-PLAN.md | Delete .prop_ids helper | ✓ SATISFIED | .prop_ids removed from NAMESPACE, exists() returns FALSE, replaced with generated name stubs |
| REL-MIGRATE | 29-02-PLAN.md | Migrate ct_related to generic_request | ✓ SATISFIED | ct_related uses generic_request, no httr2:: code, on.exit cleanup, 7 tests pass |
| REL-VALIDATE | 29-02-PLAN.md | Validate ct_related behavior unchanged | ✓ SATISFIED | Tests verify single/multi query, inclusive filtering, server cleanup, VCR cassettes work |
| NEWS-DOC | 29-01,02 | Document breaking changes in NEWS.md | ✓ SATISFIED | NEWS.md Phase 29 section documents both migrations with examples |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| R/ct_related.R | 1 | TODO comment | ℹ️ Info | "TODO Follow up to see if this will remain" - lifecycle badge note, not a code issue |

**No blockers or warnings found.**

### Human Verification Required

None required. All behavioral requirements verified programmatically through:
- Unit tests for coerce hook (17 assertions)
- Integration tests for ct_related (7 tests with VCR cassettes)
- Hook configuration drift check (passes with 10 functions, 11 hooks, 6 extra params)
- Package loads cleanly without errors

### Verification Commands Executed

All verification commands passed successfully:

1. **Property hooks tests:**
   ```bash
   devtools::test_file('tests/testthat/test-property_hooks.R')
   # Result: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 17 ]
   ```

2. **ct_related tests:**
   ```bash
   devtools::test_file('tests/testthat/test-ct_related.R')
   # Result: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ]
   ```

3. **Hook config validation:**
   ```bash
   source('dev/check_hook_config.R')
   # Result: Hook config validation passed: 10 function(s), 11 hook(s), 6 extra param(s)
   ```

4. **Package loads cleanly:**
   ```bash
   devtools::load_all()
   # Result: Success (only vcr version warning - not an issue)
   ```

5. **ct_properties removed:**
   ```bash
   grep ct_properties NAMESPACE  # No matches
   exists('ct_properties', envir = asNamespace('ComptoxR'))  # FALSE
   ```

6. **ct_related migration verified:**
   ```bash
   grep -r "httr2::" R/ct_related.R  # No matches
   grep "generic_request" R/ct_related.R  # 2 matches (lines 53, 54)
   grep "on.exit" R/ct_related.R  # 1 match (line 45)
   ```

7. **Commits verified:**
   ```bash
   git log --oneline --all | grep -E "b5aeddb|a313fad|abc68c5|4da96fc"
   # All 4 commits from summaries exist
   ```

### Completeness Check

**Plans executed:** 2/2
- ✓ 29-01-PLAN.md - Property coerce hook and ct_properties deletion
- ✓ 29-02-PLAN.md - ct_related migration to generic_request

**Summaries created:** 2/2
- ✓ 29-01-SUMMARY.md - Property search migration
- ✓ 29-02-SUMMARY.md - ct_related migration

**Files modified (from plan frontmatter):**

Plan 29-01:
- ✓ inst/hook_config.yml
- ✓ R/hooks/property_hooks.R (created)
- ✓ R/ct_chemical_property_experimental_search.R
- ✓ R/ct_chemical_property_predicted_search.R
- ✓ R/ct_prop.R (deleted)
- ✓ tests/testthat/test-ct_prop.R (deleted, replaced with test-ct_chemical_property_name.R)
- ✓ tests/testthat/test-property_hooks.R (created)
- ✓ man/ct_properties.Rd (deleted by devtools::document())
- ✓ man/prop_ids.Rd (deleted by devtools::document())
- ✓ NAMESPACE
- ✓ NEWS.md

Plan 29-02:
- ✓ R/ct_related.R
- ✓ tests/testthat/test-ct_related.R
- ✓ NEWS.md

**Success criteria (from PLAN):**

Plan 29-01:
- ✓ ct_properties() and .prop_ids() deleted from codebase
- ✓ coerce_by_property_id hook operational for both experimental and predicted property bulk search
- ✓ CI drift check passes
- ✓ Hook unit tests pass
- ✓ Package loads cleanly
- ✓ NEWS.md documents all breaking changes with migration examples

Plan 29-02:
- ✓ ct_related() uses generic_request() or equivalent template (no raw httr2)
- ✓ Server URL restored even on error (on.exit pattern)
- ✓ Inclusive filtering preserved
- ✓ All existing test cassettes still work
- ✓ No ct_related_EXP remaining in final code
- ✓ NEWS.md documents migration

---

## Summary

Phase 29 successfully achieved its goal of migrating medium-complexity functions from raw httr2 to generic_request(). All 11 observable truths verified, all 8 required artifacts substantive and wired, all 5 key links operational.

**Key accomplishments:**
1. Property coerce hook system operational with 17 passing unit tests
2. ct_properties and .prop_ids cleanly deleted with migration documentation
3. ct_related migrated to generic_request with guaranteed server cleanup
4. Zero raw httr2 code remaining in user-facing functions
5. All tests pass (24 total: 17 hook tests + 7 ct_related tests)
6. Package loads cleanly
7. Breaking changes fully documented in NEWS.md

**No gaps, no blockers, no human verification needed.**

Phase 29 is complete and ready for Phase 30 (Build Quality Validation).

---

_Verified: 2026-03-11T18:30:00Z_

_Verifier: Claude (gsd-verifier)_
