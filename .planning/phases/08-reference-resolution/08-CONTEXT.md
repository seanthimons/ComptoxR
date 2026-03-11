# Phase 8: Reference Resolution - Context

**Gathered:** 2026-01-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Parser resolves `$ref` schema references across both Swagger 2.0 (`#/definitions/`) and OpenAPI 3.0 (`#/components/schemas/`) formats, with nested reference support. This phase handles reference resolution logic only — version detection and body extraction are complete from Phase 7.

</domain>

<decisions>
## Implementation Decisions

### Fallback behavior
- Try alternate location before failing — if `#/definitions/Foo` not found, check `#/components/schemas/Foo`
- Version-aware order: Swagger 2.0 checks definitions first, OpenAPI 3.0 checks components first
- If both locations fail, abort entirely (unresolved ref is fatal for that endpoint)
- Always log when fallback location is used (not just verbose mode)

### Recursion handling
- Depth limit of 3 is acceptable (no need to make configurable)
- Circular references: detect and break the cycle, return partial schema with warning
- Depth limit behavior: Claude's discretion on truncate-vs-fail
- Depth tracking logging: Claude's discretion

### Error reporting
- Use `cli` package (cli_abort/cli_warn) consistent with rest of codebase
- Full context in errors: ref path, endpoint name, HTTP method, locations tried
- No fuzzy-match suggestions for similar schema names
- Collect all resolution failures and report together (don't fail on first)

### Edge cases
- Missing schema names: abort endpoint (fatal error)
- Malformed refs (no # prefix, wrong separators): strict validation, abort
- External file refs (other-file.json#/...): not supported, error if encountered
- Empty resolved schemas (exists but no properties): warn but treat as valid

### Claude's Discretion
- Exact depth limit enforcement behavior (truncate vs fail)
- Depth tracking log format and verbosity
- Error message formatting details

</decisions>

<specifics>
## Specific Ideas

- Error messages should include all locations tried (e.g., "Tried #/definitions/Foo, then #/components/schemas/Foo")
- Fallback logging helps debug schema authoring issues — make it visible without verbose mode

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-reference-resolution*
*Context gathered: 2026-01-29*
