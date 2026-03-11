---
phase: 25-automated-test-generation-pipeline
plan: 03
subsystem: automation-pipeline
tags:
  - github-actions
  - ci-cd
  - test-automation
  - workflow
dependency_graph:
  requires:
    - 25-01 (dev/detect_test_gaps.R script)
    - 25-02 (dev/generate_tests.R script with manifest support)
  provides:
    - Automated test gap detection in CI
    - Automated test generation in CI
    - Test gap metrics in PR bodies
  affects:
    - .github/workflows/schema-check.yml
tech_stack:
  added: []
  patterns:
    - GitHub Actions conditional step execution
    - Step output variable interpolation
    - Continue-on-error for non-blocking automation
key_files:
  modified:
    - .github/workflows/schema-check.yml
decisions:
  - "Use continue-on-error: true for both test steps to prevent blocking PR creation on test generation failures"
  - "Make test generation conditional on both schema_changes AND gaps_found to avoid unnecessary work"
  - "Position test steps between documentation update and coverage calculation per CONTEXT.md pipeline order"
  - "Add Test Gaps & Generation section to PR body between Function Stub Generation and API Coverage sections"
metrics:
  duration_mins: 1.0
  tasks_completed: 1
  files_modified: 1
  commits: 1
  completed_date: "2026-03-01"
---

# Phase 25 Plan 03: CI Integration Summary

**One-liner:** Integrated test gap detection and generation into schema-check.yml workflow with PR body reporting

## Objective

Extend the existing schema-check.yml GitHub Actions workflow to automatically detect test gaps and generate missing test files whenever schema changes are detected, with metrics reported in automated PR bodies.

## What Was Built

### Workflow Extensions

Added two new steps to `.github/workflows/schema-check.yml`:

1. **Detect test gaps** (id: gaps)
   - Runs after "Update documentation" step
   - Conditional on `schema_changes.outputs.changed == 'true'`
   - Executes `dev/detect_test_gaps.R`
   - Outputs: `gaps_found`, `gaps_count`
   - Uses `continue-on-error: true` for resilience

2. **Generate missing tests** (id: tests)
   - Runs after gap detection
   - Conditional on both schema changes AND gaps being found
   - Executes `dev/generate_tests.R`
   - Outputs: `tests_generated`, `tests_skipped`, `gaps_remaining`
   - Uses `continue-on-error: true` for resilience

### PR Body Enhancement

Extended the "Prepare PR body" step with a new "Test Gaps & Generation" section that displays:
- Gaps Detected count
- Tests Generated count
- Tests Skipped (Protected) count
- Gaps Remaining count

### Commit Message Updates

Updated the automated PR commit message and title to reflect test generation:
- Commit: "chore: update API schemas, generate function stubs and tests"
- Title: "chore: API schema and test updates"

## Pipeline Order

The complete workflow now follows the order specified in CONTEXT.md:

1. Download schemas
2. Diff schemas
3. Generate function stubs (conditional)
4. Update documentation (conditional)
5. **Detect test gaps (NEW)** (conditional)
6. **Generate missing tests (NEW)** (conditional on gaps)
7. Calculate coverage (conditional)
8. Create Pull Request

## Implementation Details

**Conditional Execution:**
- Test steps only run when `steps.schema_changes.outputs.changed == 'true'`
- Test generation only runs when `steps.gaps.outputs.gaps_found == 'true'`
- This prevents unnecessary work on runs without schema changes

**Error Handling:**
- Both test steps use `continue-on-error: true`
- If test generation fails, the workflow continues to coverage calculation and PR creation
- This ensures schema updates are never blocked by test automation issues

**Output Variables:**
- Scripts write to `GITHUB_OUTPUT` environment file
- Variables are interpolated into PR body using `${{ steps.gaps.outputs.* }}` syntax
- Default values (`|| '0'`) prevent empty fields in PR body

**No New Dependencies:**
- Scripts use packages already in workflow's `extra-packages` list
- `glue` package (used by generate_tests.R) is a transitive dependency of `cli`

## Verification Results

**YAML Validation:** PASSED
- Workflow file parses without errors

**Step Ordering:** PASSED
- Update documentation (line 187)
- Detect test gaps (line 193)
- Generate missing tests (line 201)
- Calculate coverage (line 209)

**Script References:** PASSED
- dev/detect_test_gaps.R referenced at line 198
- dev/generate_tests.R referenced at line 206

**Step IDs:** PASSED
- id: gaps at line 194
- id: tests at line 202

**PR Body Sections:** PASSED
- Test Gaps & Generation section at line 315
- API Coverage section at line 325
- Correct ordering maintained

**Output Variables:** PASSED
- steps.gaps.outputs.gaps_count referenced
- steps.gaps.outputs.gaps_found used in conditional
- steps.tests.outputs.tests_generated referenced
- steps.tests.outputs.tests_skipped referenced
- steps.tests.outputs.gaps_remaining referenced

## Deviations from Plan

None - plan executed exactly as written.

## Files Modified

1. `.github/workflows/schema-check.yml`
   - Added 2 new workflow steps (16 lines)
   - Added PR body section (10 lines)
   - Updated commit message and title (2 lines)
   - Total changes: 28 insertions, 2 deletions

## Testing

**Validation Performed:**
- YAML syntax validation via yaml::read_yaml() - PASSED
- Step ordering verification via grep - PASSED
- Script path verification - PASSED
- Output variable reference verification - PASSED

**Manual Review Required:**
- Workflow will be tested on next schema update (scheduled or manual trigger)
- First real run will validate integration with detect_test_gaps.R and generate_tests.R

## Next Steps

This completes Phase 25. The automated test generation pipeline is now fully integrated:
- Plan 01: Gap detection script ✓
- Plan 02: Test generator with manifest support ✓
- Plan 03: CI integration ✓

**Expected behavior on next schema update:**
1. Workflow downloads new schemas
2. Generates function stubs for new/changed endpoints
3. Updates documentation
4. Detects test gaps (functions without tests)
5. Generates test files for gaps (respecting protected files)
6. Updates manifest
7. Reports metrics in PR body
8. Commits schemas + stubs + tests in single PR

**Future enhancements** (out of scope for this phase):
- Add test coverage percentage to PR body
- Add links to generated test files
- Add warnings for high gap counts

## Commits

| Task | Commit | Files | Description |
|------|--------|-------|-------------|
| 1    | 801289b | 1 | Integrate test gap detection and generation into schema-check workflow |

## Self-Check: PASSED

**Files created/modified:**
✓ FOUND: .github/workflows/schema-check.yml (modified)
✓ FOUND: .planning/phases/25-automated-test-generation-pipeline/25-03-SUMMARY.md (created)

**Commits:**
✓ FOUND: 801289b (feat(25-03): integrate test gap detection and generation)

**Must-have truths verified:**
✓ Schema-check workflow includes gap detection step after documentation update
✓ Schema-check workflow includes test generation step that runs when gaps are found
✓ Test generation steps run only when schema changes are detected
✓ PR body includes "Test Gaps & Generation" section with all required metrics
✓ Generated test files will be committed alongside schemas, stubs, and docs
✓ Workflow supports both scheduled triggers and manual workflow_dispatch (unchanged)

**Key links verified:**
✓ Workflow → dev/detect_test_gaps.R via Rscript step (line 198)
✓ Workflow → dev/generate_tests.R via Rscript step (line 206)
✓ Workflow → pr_body.md via steps.gaps.outputs interpolation (lines 317-320)
✓ Workflow → pr_body.md via steps.tests.outputs interpolation (lines 318-320)
