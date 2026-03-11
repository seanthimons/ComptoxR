---
phase: 28-thin-wrapper-migration
plan: 01
subsystem: hook-system
tags: [infrastructure, hooks, yaml-config]
dependency_graph:
  requires: []
  provides:
    - HOOK-28-01  # Hook registry and dispatcher
    - HOOK-28-02  # YAML configuration system
  affects:
    - stub-generation-pipeline
tech_stack:
  added:
    - yaml::read_yaml for config loading
  patterns:
    - Session-level environment for hook storage
    - Declarative hook configuration via YAML
    - Chain-of-responsibility pattern for hook execution
key_files:
  created:
    - R/hook_registry.R              # Hook registry and dispatcher
    - inst/hook_config.yml           # Declarative hook configuration
    - tests/testthat/test-hook_registry.R  # Hook registry test suite
  modified:
    - R/zzz.R                        # Added load_hook_config() to .onLoad
decisions:
  - title: "Use match.fun() not get() for safer function lookup"
    rationale: "match.fun() provides better error messages and handles function objects correctly"
    alternatives: ["get() with explicit checks", "do.call with string names"]
  - title: "Store config in .HookRegistry environment, not .ComptoxREnv"
    rationale: "Separates hook system from general package cache, cleaner namespace"
    alternatives: ["Add to .ComptoxREnv", "Use package options"]
  - title: "No-op when hooks missing rather than error"
    rationale: "Allows gradual migration - generated stubs work before hooks implemented"
    alternatives: ["Warn on missing hooks", "Require all hooks to be defined"]
metrics:
  duration_minutes: 2
  tasks_completed: 2
  commits: 2
  files_created: 3
  files_modified: 1
  test_assertions: 11
  completed_date: "2026-03-11"
---

# Phase 28 Plan 01: Hook System Foundation

**One-liner:** Session-level hook registry with YAML configuration and run_hook() dispatcher supporting pre_request, post_response, and transform hooks for generated function customization.

## Overview

Built the foundational hook system infrastructure that enables declarative customization of generated API wrapper functions. The system uses YAML configuration to register hook chains that execute at specific lifecycle points (pre-request validation, post-response processing, data transformation).

## Tasks Completed

### Task 1: Create hook registry and YAML config
**Status:** ✅ Complete
**Commit:** f0f3400

Created R/hook_registry.R with:
- `.HookRegistry` environment for session-level hook storage
- `load_hook_config()` to populate registry from inst/hook_config.yml
- `run_hook(fn_name, hook_type, data)` dispatcher that executes hook chains in declared order
- Returns data unchanged when no hooks registered (enables gradual migration)

Created inst/hook_config.yml with initial entries for:
- `ct_lists_all`: transform hooks, return_dtxsid/coerce params
- `ct_similar`: pre_request validation, similarity param
- `ct_list`: pre_request/post_response hooks, extract_dtxsids param
- `ct_compound_in_list`: post_response formatting
- `ct_bioactivity_data_search_*`: post_response annotation hooks for 4 bulk search variants

YAML structure:
```yaml
ct_lists_all:
  extra_params:
    return_dtxsid:
      default: "FALSE"
      type: "logical"
      description: "Return all DTXSIDs contained within each list"
  transform:
    - lists_all_transform
```

**Verification:** YAML parses without errors via yaml::read_yaml()

### Task 2: Integrate .onLoad and write registry tests
**Status:** ✅ Complete
**Commit:** ac8150e

Extended R/zzz.R `.onLoad()` to call `load_hook_config()` after existing extractor/classifier initialization. Single line addition preserves existing logic.

Created tests/testthat/test-hook_registry.R with 6 test cases covering:
1. **YAML loading:** Verifies .HookRegistry$config populated with known entries
2. **No-op for missing hooks:** Returns data unchanged for unregistered functions
3. **No-op for unregistered hook type:** Returns data unchanged when hook type not defined for function
4. **Single hook execution:** Verifies hook modifies data (adds marker field)
5. **Hook chain order:** Verifies hooks execute in YAML declaration order
6. **Missing hook error:** Verifies informative error when hook function not found

**Verification:** All 11 test assertions pass via devtools::test(filter='hook_registry')

## Deviations from Plan

None - plan executed exactly as written.

## Integration Points

**Downstream dependencies (Phase 28 plans 02-03):**
- Stub generator will read inst/hook_config.yml to inject extra_params into function signatures
- Generated stubs will call run_hook() at pre_request/post_response/transform lifecycle points
- Hook implementation functions will be added as needed (lists_all_transform, validate_similarity, etc.)

**Package loading:**
- .onLoad calls load_hook_config() automatically at package load time
- No manual initialization required

## Testing Strategy

**Unit tests:** 6 test cases verify registry behavior in isolation
- Config loading from YAML
- No-op behavior for missing/unregistered hooks
- Single hook execution
- Chain ordering
- Error handling

**Not yet tested:** Actual hook implementations (deferred to plans that implement specific hooks)

## Known Limitations

1. **Hook functions not yet implemented:** YAML references functions like `lists_all_transform` that don't exist yet - normal for foundation work
2. **No validation of YAML schema:** load_hook_config() trusts YAML structure - could add validation later if needed
3. **No hook debugging utilities:** Could add dry-run or logging modes for hook chains

These are intentional - foundation establishes the *mechanism*, subsequent plans will add the *content*.

## Success Criteria Verification

- [x] .HookRegistry environment exists and is populated from inst/hook_config.yml at package load
- [x] run_hook() is a no-op for unregistered functions/hook types
- [x] run_hook() executes hook chains in declared YAML order
- [x] All hook registry tests pass (11 assertions)
- [x] devtools::document() runs clean
- [x] library(ComptoxR) loads without errors

## Files Changed

```
R/hook_registry.R                        | 58 ++++++++++++ (new)
inst/hook_config.yml                     | 71 ++++++++++++ (new)
tests/testthat/test-hook_registry.R      | 129 ++++++++++++++++++++++ (new)
R/zzz.R                                  | 3 +     (modified)
```

Total: 3 files created, 1 modified, 261 lines added

## Self-Check: PASSED

**Files created:**
- ✅ R/hook_registry.R exists
- ✅ inst/hook_config.yml exists
- ✅ tests/testthat/test-hook_registry.R exists

**Files modified:**
- ✅ R/zzz.R contains load_hook_config() call

**Commits exist:**
- ✅ f0f3400: feat(28-01): create hook registry and YAML config
- ✅ ac8150e: feat(28-01): integrate .onLoad and write registry tests

**Tests pass:**
- ✅ 11 test assertions passing
- ✅ No test failures, warnings, or skips

**Package loads:**
- ✅ library(ComptoxR) succeeds
- ✅ devtools::document() succeeds

All deliverables verified and functional.
