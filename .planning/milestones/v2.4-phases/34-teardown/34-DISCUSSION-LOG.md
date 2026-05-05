# Phase 34: Teardown - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 34-teardown
**Areas discussed:** Verification scope, DB purge method, Test file cleanup

---

## Verification Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Verify only (Recommended) | Confirm state meets criteria 1 & 2 via grep. Leave old plan doc. Focus on DB purge. | |
| Verify + clean old plan doc | Also remove or archive LIFESTAGE_HARMONIZATION_PLAN.md | ✓ |
| Full sweep | Verify + clean + scan entire repo for stale v2.3 references | |

**User's choice:** Verify + clean old plan doc
**Notes:** Old plan doc contains superseded classifier code. PLAN2.md is the active v2.4 reference.

---

## DB Purge Method

| Option | Description | Selected |
|--------|-------------|----------|
| Dev script on actual DB (Recommended) | Write dev/ script: drop tables, run baseline patch, confirm recreation on real ecotox.duckdb | ✓ |
| Temp DB in test | testthat test with minimal temp DuckDB | |
| Both | Dev script + lightweight testthat test | |

**User's choice:** Dev script on actual DB
**Notes:** Most realistic approach — uses the actual database.

---

## Test File Cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Leave as-is (Recommended) | Tests are v2.4-forward, not v2.3 artifacts. Validated in Phase 35+. | ✓ |
| Quick sanity check | Run tests to see pass/fail state, don't fix | |
| Defer to Phase 39 | Explicitly mark for revisit in Quality Gates | |

**User's choice:** Leave as-is
**Notes:** test-eco_lifestage_gate.R tests patch paths (cache-hit, baseline-seeded, live-refresh, quarantine) — these are v2.4 eco_lifestage_patch.R tests, not old v2.3 classifier tests.

---

## Claude's Discretion

- Dev script location and naming within dev/
- Grep patterns for verification checks
- Whether verification output is part of the dev script or separate

## Deferred Ideas

None — discussion stayed within phase scope.
