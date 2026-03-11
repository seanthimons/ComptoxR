# Phase 29: Direct Template Migration - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Migrate the remaining medium-complexity functions that use raw httr2 to generic_request(). This covers ct_properties (dual-mode dispatcher), .prop_ids() helper, and ct_related (ad-hoc web scraper). After this phase, no hand-written ct_* functions should contain raw httr2 calls.

</domain>

<decisions>
## Implementation Decisions

### ct_properties Migration
- Delete ct_properties entirely — users call generated stubs directly
- Compound search path: users call ct_chemical_property_search_bulk() (already exists as generated stub)
- Property range path: users call ct_chemical_property_experimental_search_by_range() and ct_chemical_property_predicted_search_by_range() (already exist as generated stubs)
- Verify existing range stubs work correctly with path_params before deleting ct_properties
- Add coerce as a hook parameter to ct_chemical_property_search_bulk — splits results by propertyId into list of data frames (consistent with annotate hook pattern from Phase 28)
- Document migration paths in NEWS.md

### .prop_ids() Helper
- Delete entirely — generated stubs ct_chemical_property_predicted_name() and ct_chemical_property_experimental_name() already exist
- Users call those stubs directly for property name lookups
- Document replacement in NEWS.md

### ct_related Migration
- Migrate to generic_request() — do NOT use stub generation (lifecycle badge protects it)
- Create ct_related_EXP() in the same file (R/ct_related.R) for head-to-head testing against original
- Use generic_request(batch_limit=1) for path-based GET — let generic_request handle per-ID loop
- Inline server switch: ctx_server(9) before call, ctx_server(1) after with on.exit/withr::defer cleanup — no hooks needed since stub generation won't touch this function
- Preserve inclusive filtering logic in post-processing
- After head-to-head validation: delete old ct_related, rename ct_related_EXP to ct_related
- Keep lifecycle::questioning badge — function stability depends on the endpoint, not our code

### Breaking Change Strategy
- Same clean break approach as Phase 28 for ct_properties and .prop_ids() — no deprecation shims
- ct_related keeps its name (migration, not deletion)

### Claude's Discretion
- Exact coerce hook implementation for property search (split by propertyId)
- How generic_request handles the related-substances endpoint path structure
- Error handling approach in ct_related_EXP (generic_request's built-in vs custom)
- Whether to preserve cli messaging from original ct_related

</decisions>

<specifics>
## Specific Ideas

- ct_related_EXP naming convention allows side-by-side testing before swap
- The coerce hook for property search follows the exact same pattern as annotate_assay_if_requested from Phase 28
- generic_request(batch_limit=1) already handles path-based GET for single items — this is the proven pattern for ct_related's per-DTXSID fetching

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- generic_request() with batch_limit=1: Handles path-based GET, per-item looping, error handling
- Hook system from Phase 28: .HookRegistry, run_hook(), inst/hook_config.yml — ready for coerce hook
- R/hooks/list_hooks.R: Contains similar split/coerce patterns (lists_all_transform)

### Established Patterns
- Phase 28 coerce hook: ct_lists_all used split() + purrr for coercion — same pattern for property search
- Phase 28 clean break: Delete wrapper, document migration in NEWS.md, no deprecation
- batch_limit=1 pattern: Used by many generated stubs for single-item path-based endpoints

### Integration Points
- inst/hook_config.yml: Add ct_chemical_property_search_bulk entry with coerce extra_param
- R/hooks/: Add property_hooks.R with coerce_by_property_id() hook function
- R/ct_related.R: Add ct_related_EXP alongside existing function
- NEWS.md: Document ct_properties and .prop_ids() removal + migration paths

</code_context>

<deferred>
## Deferred Ideas

- Auditing all 400+ generated stubs for hook opportunities — Phase 30 or future work
- ct_related endpoint stability assessment — depends on EPA API roadmap, not our code

</deferred>

---

*Phase: 29-direct-template-migration*
*Context gathered: 2026-03-11*
