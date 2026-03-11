# Phase 28: Thin Wrapper Migration - Context

**Gathered:** 2026-03-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a deterministic hook injection system so customizations survive stub regeneration at scale, then migrate all hand-written ct_* functions (thin wrappers, complex dispatchers, deprecated code) to generated stubs + hooks. Delete old friendly-name wrappers — generated stub names become the public API.

</domain>

<decisions>
## Implementation Decisions

### Hook System Architecture
- **Registry:** `.HookRegistry` environment populated at `.onLoad` from `inst/hook_config.yml`
- **Hook files:** `R/hooks/` directory, grouped by function family
- **Config format:** YAML in `inst/hook_config.yml` with YAML list syntax for chains
- **Hook types:** pre_request, post_response, and transform (replaces default parse pipeline)
- **Chain order:** pre_request → (generic_request) → transform OR default parse → post_response
- **No-op handling:** Runtime — `run_hook('fn_name', 'type', data)` returns input unchanged if nothing registered
- **Composability:** Shared reusable primitives (validate_dtxsid, flatten_nested, etc.) composed per-function via YAML lists

### Hook Parameter Injection (decided via structured debate)
- **Mechanism:** YAML `extra_params` section in `inst/hook_config.yml` declares parameters per function
- **Generator reads config:** Extends existing pagination pattern (append to fn_signature, add @param docs)
- **CI enforcement:** Config-drift check blocks build if YAML extra_params don't match generated formals
- **Rationale:** Only option where failure mode (config drift) is detectable by CI; produces explicit typed params with IDE autocomplete; ~50 lines extending proven generator code path

### Function Migration Strategy
- **Pure pass-throughs (8 functions):** Delete immediately — ct_hazard, ct_cancer, ct_env_fate, ct_demographic_exposure, ct_general_exposure, ct_functional_use, ct_functional_use_probability, ct_genotox. No behavior to preserve.
- **Pre-hook needed (2):** ct_similar (validation), ct_list (str_to_upper)
- **Post-hook needed (1):** ct_compound_in_list (extract/format/cli messages)
- **Transform needed (1):** ct_lists_all (conditional projection + coerce/split)
- **Break apart + hooks (1):** ct_bioactivity → 4 separate stubs (by dtxsid, aeid, spid, m4id), each gets annotate post-hook for optional assay join
- **Break apart + hooks (1):** ct_properties → compound search stub with coerce post-hook, property range stub with path_params. .prop_ids helper evaluated for migration.
- **Naming:** No aliases. Users call generated names directly (e.g., ct_hazard_toxval_search_bulk instead of ct_hazard). Clean break, no deprecation shim.

### Deprecated/Dead Code
- **ct_descriptors:** Delete entirely (deprecated, undocumented INDIGO endpoint, raw httr2)
- **ct_synonym:** Delete (empty file, 0 lines) after confirming generated stub exists
- **ct_related:** Leave untouched — it's an ad-hoc web scraper, not a standard API wrapper. May never fit the stub model. Evaluate deeper during research.

### Testing Strategy
- **Hook tests:** Unit tests with mock data (hand-crafted tibbles/lists). Test each primitive in isolation. No VCR needed.
- **Test generator:** Updated to read hook_config.yml and auto-generate test variants exercising hook params (e.g., with/without annotate=TRUE)
- **CI drift check:** Blocks build (error, not warning) if YAML extra_params don't match generated function formals

### Claude's Discretion
- Exact hook registry implementation (environment structure, lookup optimization)
- Hook primitive function signatures and internal composition mechanics
- Generator code structure for reading YAML config and injecting extra_params
- Which reusable primitives to extract vs. function-specific hooks
- How to structure the CI config-drift check script

</decisions>

<specifics>
## Specific Ideas

- The pagination injection pattern (lines 357-401 of build_function_stub) is the exact mechanical precedent — append to fn_signature string, add @param doc, inject default value
- Generated stubs already have `# Additional post-processing can be added here` placeholder comments — these become the hook call points
- ct_bioactivity's 4 stubs all share the same annotate post-hook — demonstrates composability (one primitive, multiple consumers)
- ct_properties' .prop_ids() helper may become a utility function or hook primitive depending on research findings

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `build_function_stub()` (dev/endpoint_eval/07_stub_generation.R): Handles all stub generation, already has pagination param injection pattern
- `generic_request()` / `generic_chemi_request()` (R/z_generic_request.R): Request templates that stubs delegate to
- `tests/testthat/helper-vcr.R`: VCR config with cassette management helpers
- `dev/generate_tests.R`: Test generator that reads function signatures — will need hook-config awareness

### Established Patterns
- Pagination already injects `all_pages = TRUE` into signatures via fn_signature string append (lines 357-401)
- Generator validates @param/formals consistency (lines 1041-1073) — hook params will be covered automatically
- `# Additional post-processing can be added here` comments in generated stubs — natural hook insertion points
- `.StubGenEnv` environment pattern for cross-call state tracking — similar pattern for `.HookRegistry`

### Integration Points
- `inst/hook_config.yml` → read by generator at generation time AND by .onLoad at runtime
- `R/hooks/` → new directory sourced as part of package (R/ auto-sources all .R files)
- Generator's `build_function_stub()` needs config-reading extension
- `dev/generate_tests.R` needs hook_config.yml awareness for test variant generation
- CI workflow needs config-drift check step

</code_context>

<deferred>
## Deferred Ideas

- Auditing all 400+ stubs for potential hook opportunities — Phase 29/30 concern
- ct_related migration — may never fit stub model, evaluate separately
- `hooks = list()` namespace pattern (Gadfly alternative from debate) — revisit if hook param count exceeds ~30 functions
- Post-processing recipe system (#120) — still deferred per earlier project decision

</deferred>

---

*Phase: 28-thin-wrapper-migration*
*Context gathered: 2026-03-10*
