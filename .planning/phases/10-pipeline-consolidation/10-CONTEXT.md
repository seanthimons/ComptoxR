# Phase 10: Pipeline Consolidation - Context

**Gathered:** 2026-01-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Refactor `generate_stubs.R` to use `openapi_to_spec()` for all schema types (ct, chemi, cc), removing divergent code paths. The script should be sourceable top-to-bottom to regenerate all stubs.

</domain>

<decisions>
## Implementation Decisions

### Generator function pattern
- Top-to-bottom script execution — source() runs everything sequentially
- Keep endpoint_eval/*.R modules — generate_stubs.R sources them
- Allow per-schema config — schema-specific options (output dir, prefix, exclusions) via config list
- All schemas follow same pattern: load JSON → preprocess → openapi_to_spec() → render

### parse_chemi_schemas() handling
- Claude's discretion to delete or keep based on usage analysis
- Claude's discretion to migrate useful parts or let them go — openapi_to_spec() is source of truth

### Endpoint filtering
- ENDPOINT_PATTERNS_TO_EXCLUDE with per-schema overrides allowed
- Schema-specific exclusions defined in 00_config.R (e.g., ENDPOINT_PATTERNS_TO_EXCLUDE_CHEMI)
- Filter before openapi_to_spec() — preprocess JSON before parsing

### Output verification
- Diff existing stubs against regenerated output
- Improvements OK — new stubs from better body extraction are acceptable differences
- GH Action alignment is separate follow-up (not part of this phase)

### Claude's Discretion
- Whether to delete or deprecate parse_chemi_schemas()
- Whether to migrate any unique logic from parse_chemi_schemas()
- Exact structure of per-schema config
- Technical approach to diffing stubs

</decisions>

<specifics>
## Specific Ideas

- User wants to "just source the entire document" — script should work with simple source() call
- GH Action should eventually run same script (follow-up, not this phase)

</specifics>

<deferred>
## Deferred Ideas

- GH Action verification (VAL-01) — separate follow-up after local script works
- CI alignment — ensure GH Action produces identical output

</deferred>

---

*Phase: 10-pipeline-consolidation*
*Context gathered: 2026-01-29*
