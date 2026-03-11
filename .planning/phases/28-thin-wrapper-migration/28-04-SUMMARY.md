---
phase: 28-thin-wrapper-migration
plan: 04
status: complete
started: 2026-03-11
completed: 2026-03-11
---

## Summary

Extended the stub generator to inject hook parameters from YAML config and created CI drift detection.

## What Was Built

### Generator Hook Integration (dev/endpoint_eval/07_stub_generation.R)
- Reads inst/hook_config.yml at generation time
- Injects extra_params into function signatures with defaults
- Adds @param roxygen docs for each extra param
- Inserts run_hook() calls at pre_request and post_response lifecycle points
- Non-hook stubs remain completely unchanged (has_hooks flag gates all modifications)

### CI Drift Check (dev/check_hook_config.R)
- Validates all YAML-referenced hook functions exist as actual R functions
- Checks declared extra_params appear in generated stub signatures
- Handles multi-function stub files by searching all R files for definitions
- Fails build on config-param mismatch

### Wrapper Deletion
Deleted 5 remaining hand-written wrappers replaced by hook-powered generated stubs:
- ct_lists_all.R → ct_chemical_list_all with lists_all_transform hook
- ct_bioactivity.R → 4 individual endpoint stubs with annotate_assay_if_requested hook
- ct_similar.R → generated stub with validate_similarity pre-request hook
- ct_list.R → generated stub with uppercase_query + extract_dtxsids_if_requested hooks
- ct_compound_in_list.R → generated stub with format_compound_list_result hook

## Key Files

### Created
- dev/check_hook_config.R — CI drift detection script

### Modified
- dev/endpoint_eval/07_stub_generation.R — hook parameter injection + hook call insertion

### Deleted
- R/ct_lists_all.R, R/ct_bioactivity.R, R/ct_similar.R, R/ct_list.R, R/ct_compound_in_list.R

## Decisions
- 4 bioactivity stubs need regeneration with annotate param (expected — stubs generated before hook integration, handled in 28-05)
- NEWS.md updated with comprehensive breaking changes and migration paths

## Self-Check: PASSED
- Generator parses without errors
- CI drift check script created and functional
- Package builds and loads cleanly after wrapper deletions
