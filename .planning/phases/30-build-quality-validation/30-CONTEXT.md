# Phase 30: Build Quality Validation - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

R CMD check produces 0 errors. Fix blocking issues (missing yaml dependency, duplicate endpoint argument if it causes errors). Warnings and notes are acceptable — doc line widths and cosmetic notes don't block this phase.

</domain>

<decisions>
## Implementation Decisions

### R CMD check target
- 0 errors — the only hard requirement
- Warnings (doc line widths) and notes (cosmetic) are acceptable and left alone
- Byte-compile notes (e.g., "formal argument matched by multiple actual arguments") only fixed if they cause installation errors

### Missing yaml dependency
- Add `yaml` to Imports in DESCRIPTION (not Suggests)
- Hook system (.onLoad reads inst/hook_config.yml) is core functionality — yaml must always be present
- No graceful fallback needed

### Duplicate endpoint argument
- The bioactivity stub has `generic_request(endpoint = ..., endpoint = ...)` — fix only if R CMD check treats it as an error
- If it's just a note, leave it for now

### Verification approach
- User will run tests and R CMD check themselves
- Phase deliverable is getting the code lined up — all fixes applied, ready for user verification

### Claude's Discretion
- Whether to scan all generated stubs for similar argument-matching issues
- How to structure fixes (single plan vs multiple)
- Whether to run devtools::document() after DESCRIPTION changes

</decisions>

<specifics>
## Specific Ideas

- The yaml dependency was introduced by Phase 28's hook system but never added to DESCRIPTION — a gap in Phase 28's validation
- User wants a lean phase — fix what blocks, don't polish cosmetics

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `R/zzz.R`: .onLoad calls load_hook_config() which uses yaml::read_yaml()
- `R/hooks.R`: Hook registry system using yaml package
- `inst/hook_config.yml`: Hook configuration read at package load time

### Established Patterns
- DESCRIPTION Imports section already has ~15 dependencies — adding yaml follows existing pattern
- Phase 28 established hook system architecture; Phase 30 just fixes the dependency declaration

### Integration Points
- DESCRIPTION: Add yaml to Imports
- Generated stubs: Check for duplicate endpoint argument in bioactivity stubs
- NAMESPACE: devtools::document() will update after DESCRIPTION changes

</code_context>

<deferred>
## Deferred Ideas

- Lifecycle promotion of user-facing functions to @lifecycle stable — future work
- Full test coverage audit of migrated functions — future work
- Fixing doc line width warnings — cosmetic, not blocking

</deferred>

---

*Phase: 30-build-quality-validation*
*Context gathered: 2026-03-11*
