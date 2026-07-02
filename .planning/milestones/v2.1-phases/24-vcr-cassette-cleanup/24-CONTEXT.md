# Phase 24: VCR Cassette Cleanup - Context

**Gathered:** 2026-02-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Clean up VCR cassette infrastructure: delete 673 bad untracked cassettes, build helper functions for cassette management (delete, list, audit), verify API key filtering across all committed cassettes, and create a batched re-recording script with parallel execution. Does NOT include writing new tests or modifying test logic — that's Phase 25.

</domain>

<decisions>
## Implementation Decisions

### Helper function design
- All helpers live in `tests/testthat/helper-vcr.R` — NOT exported as package functions
- `delete_all_cassettes()` and `delete_cassettes(pattern)` default to dry-run mode — must pass `dry_run = FALSE` to actually delete files
- `list_cassettes()` returns a simple character vector of cassette filenames (no metadata)
- `check_cassette_safety()` accepts optional cassette name or pattern — no args scans all cassettes

### Bad cassette deletion strategy
- All 673 untracked .yml files in `tests/testthat/fixtures/` are from the bad generator run — delete all of them
- Use the newly built helper functions to perform the deletion (dogfooding the tools)
- Separate commits: one commit adds helper functions, another commit deletes bad cassettes using them

### Re-recording strategy
- Priority domains for first re-recording batch: Chemical (`ct_chemical_*`), `chemi_search`, `chemi_resolver_lookup`
- Parallel execution using `mirai` with 8 workers
- Exponential backoff on HTTP 429 (rate limit) responses
- On failure (API error, timeout): skip the cassette, log it to a failures file, continue with remaining cassettes
- Re-run failures separately after initial batch completes

### API key audit
- Scan current working tree cassettes only — no git history scanning
- Check for: actual API key string values AND auth-related headers (Authorization, Bearer, x-api-key with real values)
- Report-only mode: print which cassettes have issues and where, no auto-fix
- Manual tool — no pre-commit hook integration

### Claude's Discretion
- Whether to keep or delete currently tracked (committed) cassettes based on validity assessment
- Exact backoff timing/curve for rate limit handling
- Re-recording script file location and naming
- Failure log format

</decisions>

<specifics>
## Specific Ideas

- User wants `mirai` for parallel re-recording — it's already installed in the project
- Chemical domain and chemi_search/chemi_resolver_lookup are explicitly the highest priority for re-recording
- Dry-run as default for destructive operations is a firm requirement

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 24-vcr-cassette-cleanup*
*Context gathered: 2026-02-27*
