# Phase 14: Integration & CI - Context

**Gathered:** 2026-01-30
**Status:** Ready for planning

<domain>
## Phase Boundary

End-to-end verification and CI/CD integration for the stub generation pipeline. Parse real production schemas, generate stubs, verify via full execution with VCR cassettes. Enforce coverage thresholds. GHA workflow runs on PRs and blocks merge on failure.

</domain>

<decisions>
## Implementation Decisions

### E2E Test Scope
- Test all 3 microservices: CompTox Dashboard, Cheminformatics, EPI Suite
- Use real schemas from `schema/` directory (not test fixtures)
- Full execution verification: actually call the generated functions
- Mock API calls with VCR cassettes (record once, replay in CI)

### Coverage Strategy
- Use `covr::file_coverage()` to measure dev/endpoint_eval/ coverage
- Enforce thresholds: CI fails if R/ <75% or dev/ <80%
- Upload to Codecov.io for visual reports and PR comments
- Separate checks: two explicit CI checks for R/ and dev/ coverage independently

### GHA Workflow Behavior
- Run on PRs only (not on merge to main)
- Separate workflow: new `pipeline-tests.yml` independent from R-CMD-check
- Ubuntu only runner (sufficient for code generation logic)
- Required check: PR cannot merge until pipeline tests pass

### Failure Handling
- Capture generated stub + error message as artifacts when E2E tests fail
- Codecov PR comment shows coverage diff when threshold is missed
- CI auto-update option: workflow dispatch to re-record VCR cassettes
- Auto-create GitHub issue when main branch tests fail

### Claude's Discretion
- VCR cassette organization and naming
- Exact artifact upload structure
- GitHub issue template for auto-created issues
- Codecov configuration details

</decisions>

<specifics>
## Specific Ideas

- Follow existing VCR patterns from `helper-vcr.R` for cassette management
- Workflow dispatch for cassette re-recording should require API key as secret input

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 14-integration-ci*
*Context gathered: 2026-01-30*
