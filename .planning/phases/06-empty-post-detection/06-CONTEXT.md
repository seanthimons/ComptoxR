# Phase 6: Empty POST Detection - Context

**Gathered:** 2026-01-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Skip stub generation for POST endpoints with incomplete schemas (no params + empty body) and warn about suspicious endpoints (optional-only params). Users receive clear feedback during generation runs.

</domain>

<decisions>
## Implementation Decisions

### Detection Criteria
- Skip POST endpoints with empty body AND no query/path params
- "Empty body" means ANY of: `{type: object}` with no properties, missing schema, null schema, undefined content
- Endpoints with ANY query param (required or optional) are NOT skipped — they're valid
- Endpoints with only optional query params: generate the stub BUT warn (suspicious)
- GET endpoints are never affected — only POST endpoints

### Warning Format
- Warnings batched at end of generation (not inline)
- Include: method + path + reason
- Use `cli::cli_warn()` for both skipped and suspicious
- Use different cli styling/colors to distinguish skipped vs suspicious
- Skipped: one style (e.g., red/bold)
- Suspicious: different style (e.g., yellow/italic)

### Summary Format
- Show count first: "3 endpoints skipped, 2 suspicious"
- Details appear below the count (Claude decides exact formatting)
- If nothing skipped/suspicious: brief confirmation "All endpoints generated successfully"
- Write to log file for later reference

### Claude's Discretion
- Exact wording for suspicious endpoint warnings
- How details are formatted below the count (list vs table vs grouped)
- Log file location and format
- Exact cli styling choices for skipped vs suspicious

</decisions>

<specifics>
## Specific Ideas

- Example endpoint to test against: `API/predictor/predict` — POST with `{type: object}` but no properties
- The warning about suspicious endpoints should hint that API docs may be incomplete

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-empty-post-detection*
*Context gathered: 2026-01-29*
