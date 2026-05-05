# Phase 38: Runtime API Finalization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 38-runtime-api-finalization
**Areas discussed:** Column contract exactness, Missing or stale DB behavior, Plumber route parity, Verification style

---

## Column Contract Exactness

| Option | Description | Selected |
|--------|-------------|----------|
| Full output by default | Keep all source-backed lifestage provenance columns visible in default `eco_results()` output. | |
| Compact by default | Show only the human-facing lifestage columns by default; add provenance columns through a flag. | yes |
| Keep `organism_lifestage` visible by default | Preserve the ECOTOX code for compatibility/debugging. | |
| Hide `organism_lifestage` by default | Use the code for joins internally, then hide it from default output because `org_lifestage` is the human-readable original value. | yes |

**User's choice:** Compact by default, with `lifestage_details = FALSE` as the flag.

**Notes:** The user wants at minimum the original life stage, harmonized life stage, and reproductive stage. The user pushed back on preserving `organism_lifestage` for compatibility because there are no existing users; broad output cleanup is acceptable. `organism_lifestage` should remain available only in detailed/debug mode.

---

## Missing or Stale DB Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Fail loudly | Abort when required lifestage tables or columns are missing. | yes |
| Return compact columns as `NA` | Continue with missing harmonization fields. | |
| Warn and continue | Warn about the missing schema but still return rows. | |

**User's choice:** Fail loudly, with clarification that stale DBs should be rare.

**Notes:** The user challenged whether an old lifestage schema can exist in normal operation. The realistic cases are development/cached DB edges: package code updated without rebuilding or patching the local DB, old test fixtures, a partially failed patch, manual DB modification, or CI cache restoring an old DuckDB artifact. The locked behavior is an invariant check, not a normal recovery path.

---

## Plumber Route Parity

| Option | Description | Selected |
|--------|-------------|----------|
| Same public contract | Apply compact/default and detailed column behavior to local DuckDB and Plumber routes. | yes |
| DuckDB only | Limit Phase 38 to local DuckDB runtime output. | |
| DuckDB now, defer Plumber parity | Capture Plumber parity as a future gap. | |

**User's choice:** Same public contract.

**Notes:** `eco_results()` should present the same output shape regardless of backend route. This supports the roadmap phrase that `ontology_id` is absent from any `eco_results()` output.

---

## Verification Style

| Option | Description | Selected |
|--------|-------------|----------|
| Testthat plus limited devtools/testthat check | Durable tests for the contract, verified through a narrow command focused on runtime API behavior. | yes |
| Add `dev/lifestage/validate_38.R` too | Add a human-readable validation script in addition to tests. | |
| Dedicated validation script first | Use a dev script as the main gate and keep tests minimal. | |

**User's choice:** Option 1 with caveat.

**Notes:** The caveat is important: verification should be a very limited devtools/testthat check instead of the full build and full package test suite. Full package checks are too broad for this narrow phase acceptance path.

---

## Agent's Discretion

- Exact implementation mechanics for hiding `organism_lifestage` from default output while preserving it in detailed mode.
- Exact test file placement.
- Exact limited verification command, provided it avoids the full build/test suite and covers the Phase 38 runtime contract.

## Deferred Ideas

- Public patch/rebuild API remains out of scope.
- Dedicated `dev/lifestage/validate_38.R` is deferred unless testthat coverage is not enough.
- Full package `devtools::check()` remains a broader release gate, not the narrow Phase 38 acceptance check.
