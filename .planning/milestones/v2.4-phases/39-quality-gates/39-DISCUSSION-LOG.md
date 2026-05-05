# Phase 39: Quality Gates - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 39-quality-gates
**Areas discussed:** Adapter Test Boundary, Failure And Fallback Coverage, Offline Enforcement, Release Documentation And Dev Scripts

---

## Adapter Test Boundary

| Question | Selected | Alternatives considered |
|----------|----------|-------------------------|
| How should mocked provider tests be anchored? | Direct adapter tests | Resolver-path tests; both but minimal; planner decides |
| Where should tests live? | Extend `test-eco_lifestage_gate.R` | Create `test-eco_lifestage_providers.R`; planner decides |
| What counts as happy path? | Minimal schema contract | Ranking-ready row; full parsed response fidelity; planner decides |
| Include provider-specific checks? | Yes | Generic candidate output only; planner decides |
| Allow cassettes or fixtures? | No cassettes, inline mocked responses only | Small fixture files; VCR cassettes; planner decides |

**Notes:** Tests should directly cover OLS4, NVS, and BioPortal provider adapter contracts without live provider dependencies.

---

## Failure And Fallback Coverage

| Question | Selected | Alternatives considered |
|----------|----------|-------------------------|
| Required failure cases? | Exception plus empty response for each provider | One representative failure; full provider-specific matrix; planner decides |
| What should fallback tests prove? | Planner discretion | Direct degradation only; resolver continuation; both |
| Require missing BioPortal key test? | Planner discretion | Required; unauthorized/request failure only |
| Empty response behavior? | Silent empty tibble is fine | Warn on empty provider responses; planner decides |

**Notes:** Actual request/auth failures should warn. Valid empty results should not warn.

---

## Offline Enforcement

| Question | Selected | Alternatives considered |
|----------|----------|-------------------------|
| Strictness of no-live-provider guard? | Sentinel mocks for live request execution | Trust mocked bindings; environment-only proof; planner decides |
| Verification command/script? | `devtools::test(filter = "eco_lifestage_gate")` | Add/update dev script; both; planner decides |
| How prove no network/API key? | Tests themselves enforce it | Document command only; CI-specific note; planner decides |
| Scope of offline tightening? | Also inspect/tighten existing live-refresh tests | Only new provider tests; planner decides |

**Notes:** Existing live-refresh/force tests should be checked for unmocked provider leakage after additional providers were added.

---

## Release Documentation And Dev Scripts

| Question | Selected | Alternatives considered |
|----------|----------|-------------------------|
| What should `NEWS.md` cover? | Drop the NEWS gate because there are no users yet | Focused breaking entry; broader v2.4 rewrite; one-line note; planner decides |
| Add a new dev validation script? | No new dev script | Update existing scripts; add `validate_39.R`; planner decides |
| Update roadmap/requirements now? | Record in context only | Planner should update planning docs; planner decides |

**Notes:** The `NEWS.md` success criterion in the roadmap is treated as obsolete for Phase 39. Existing dev scripts should only be changed if stale validation would mislead maintainers.

## Agent's Discretion

- Whether to add one resolver-continuation smoke test after direct adapter tests.
- Whether BioPortal missing-key coverage is separate from unauthorized/request-failure coverage.
- Exact inline payload shape and warning assertions.

## Deferred Ideas

- No new Phase 39 dev validation script.
- No `NEWS.md` entry for `ontology_id` removal unless the roadmap is later revised.
- No roadmap/requirements mutation during this discuss workflow.
