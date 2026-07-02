# Known Debt — Areas Requiring Extra Scrutiny

> **Purpose:** These areas had documentation gaps discovered on 2026-03-09. Summaries were
> written retroactively after investigating git history and disk state. The code works, but
> the summaries were reconstructed from evidence rather than written at execution time.
>
> **When debugging:** Check these areas FIRST. If something doesn't match the summary,
> the summary may be wrong — trust the code and git history over the retroactive docs.

## 1. Test Generator Core (Phase 23, Plan 03)

**Summary:** `.planning/phases/23-build-fixes-test-generator-core/23-03-SUMMARY.md`
**Status:** Retroactive — written 2026-03-09

**Files to verify against summary claims:**
- `dev/generate_tests.R` — 5 core functions (extract_function_formals, extract_tidy_flag, get_test_value_for_param, get_batch_test_values, generate_test_file)
- `tests/testthat/test-test-generator.R` — 19 test blocks, claimed 66+ assertions

**What was verified at investigation time:**
- All 5 functions exist and are callable
- Test file runs: 0 failures, 66 passing assertions
- Git commits 15d903e and 8f28743 match the described work

**What was NOT independently verified:**
- Whether every TGEN requirement is fully covered (we confirmed function existence, not behavioral correctness)
- Whether the parameter mapping table in get_test_value_for_param() is complete for all current functions
- Whether generate_test_file() handles all edge cases in the current codebase (functions added after 2026-02-27)

**If debugging test generation issues, check:**
- Parameter mapping gaps: does get_test_value_for_param() cover the param name causing the failure?
- Tidy flag extraction: does extract_tidy_flag() handle the function's specific call pattern?
- Cassette naming: are names unique across all generated tests, or did a collision sneak in?

---

## 2. Stub Purge & Regeneration (Phase 23, Plan 04)

**Summary:** `.planning/phases/23-build-fixes-test-generator-core/23-04-SUMMARY.md`
**Status:** Copied from milestones archive — written at execution time but stored in wrong directory

**Files to verify against summary claims:**
- `R/ct_*.R`, `R/chemi_*.R` — 230 regenerated stubs
- NAMESPACE, man/*.Rd — regenerated via devtools::document()

**What was verified at investigation time:**
- Summary existed in `.planning/milestones/v2.1-phases/` (was a filing error, not a content gap)
- R CMD check currently shows 0 errors (matches summary claim)
- Git commits b2b1d58 and 89a8672 match the described work

**What was NOT independently verified:**
- Whether all 230 stubs are still in their regenerated state (later work may have modified some)
- Whether the 4 build fixes (duplicate endpoint param, unicode, roxygen links, partial arg match) are still intact

**If debugging build or stub issues, check:**
- Has a subsequent schema update or stub regeneration overwritten the fixes from 89a8672?
- Are the 6 warnings and 3 notes still the same, or have new ones appeared?

---

## 3. Test Gap Detection & Manifest (Phase 25, Plan 01)

**Summary:** `.planning/phases/25-automated-test-generation-pipeline/25-01-SUMMARY.md`
**Status:** Retroactive — written 2026-03-09

**Files to verify against summary claims:**
- `dev/detect_test_gaps.R` — 342 lines, 7 functions
- `dev/test_manifest.json` — tracks generated vs protected test files
- `dev/reports/` — gap detection output directory

**What was verified at investigation time:**
- Script runs and produces output (found 34 gaps on 2026-03-09)
- All 7 functions exist and are callable
- Manifest JSON is valid and contains 42 tracked files
- Git commit 6d0b221 matches the described work

**What was NOT independently verified:**
- Whether calls_generic_request() AST detection catches all current API wrapper patterns
- Whether the 34 gaps are all genuine (vs false positives from non-API functions)
- Whether manifest entries are current (the manifest was last auto-updated 2026-03-09 but may drift)
- Whether detect_stale_protected() correctly identifies stale entries

**If debugging test gap or manifest issues, check:**
- Is calls_generic_request() detecting the function's generic_request call? (AST-based, may miss indirect calls)
- Is the manifest out of sync with actual test files on disk?
- Are duplicate manifest helpers (in both detect_test_gaps.R and generate_tests.R) still in sync with each other?

---

## Resolution Protocol

When an item on this list has been fully verified through actual use (not just investigation):
1. Add a "Verified" line with date and evidence
2. Once all items in a section are verified, move the section to "Resolved" at the bottom
3. When all sections are resolved, delete this file

## Resolved

(None yet)
