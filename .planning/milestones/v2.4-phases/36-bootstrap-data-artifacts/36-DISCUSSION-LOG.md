# Phase 36: Bootstrap Data Artifacts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 36-bootstrap-data-artifacts
**Areas discussed:** Gap remediation, Cross-ontology contamination, Completeness check, Cross-check gate home, Future-release refresh

---

## 1. Cross-check gap remediation

**Diagnostic surfaced during discussion:** cross-check gate currently fails — 7 resolved baseline rows have no matching `(source_ontology, source_term_id)` in `lifestage_derivation.csv` (4 NVS S11, 2 PO, 1 cross-ontology `GO:0040007` mislabeled as UBERON).

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Hand-author 7 derivation rows | Fastest; keeps existing scoring metadata intact; straightforward mapping for NVS/PO | ✓ |
| (b) Re-resolve everything live and regenerate both CSVs | Most correct but doesn't actually produce derivation rows (always curator-authored); re-runs 139 resolutions | |
| (c) Demote 7 rows to `unresolved` in baseline | Loses 18 working resolutions | |

**User's choice:** (a)

**Follow-up — regex backstop:**

| Option | Description | Selected |
|--------|-------------|----------|
| Silent regex backstop (auto-assign harmonized category via label pattern) | Convenient but recreates v2.3 cosmetic-provenance problem; hides the gate | |
| Suggestion-only tool (writes proposals, never auto-promotes) | Reduces curator labor while preserving source-backed guarantee | (surfaced later as Area 5 refresh mechanism) |
| No backstop | Keeps gate strict; source-backed guarantee intact | ✓ |

**User's choice:** no backstop

**Notes:** User aligned with assistant's pushback that a silent regex backstop would recreate v2.3's cosmetic-provenance problem. Suggestion-only pattern was surfaced as a lower-risk alternative and later chosen for Area 5.

---

## 2. Cross-ontology contamination (`GO:0040007`)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Re-resolve 3 contaminated rows with Phase-35 prefix-filtered OLS4 | Fresh provenance; expected `unresolved`; targeted script | ✓ |
| (b) Hand-correct `source_ontology` to `GO` + add derivation row | Expands canonical provider set to GO; out of milestone scope | |
| (c) Flip 3 rows to `unresolved` in baseline directly | Honest but skips live verification that prefix filter works | |
| (d) Delete the 3 rows entirely | Violates baseline coverage requirement | |

**User's choice:** (a)

**Notes:** Re-resolution will exercise the Phase 35 prefix-filtered OLS4 adapter end-to-end on known-contaminated terms. Expected endpoint is `unresolved`; if any provider surprise-matches, that candidate becomes a new derivation key subject to normal curator review.

---

## 3. ECOTOX completeness check

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Rebuild DB via `.eco_patch_lifestage(refresh="baseline")` then anti-join | Wrong — patch doesn't create `lifestage_codes` table | |
| (a′) Assume developer has DB available; script auto-detects and skips gracefully if absent | Pragmatic; live anti-join when DB is present | ✓ |
| (b) One-shot extract from fresh ECOTOX zip | Heavy; touches full build pipeline | |
| (c) Trust 139 snapshot; rely on runtime quarantine | Criterion 1 goes untested | |
| (d) Commit `inst/extdata/ecotox/lifestage_codes_snapshot.csv` fixture | CI-friendly; new artifact to maintain | |
| (d′) Same as (d) in `dev/` instead | Middle ground | |

**User's choice:** (a′)

**Notes:** User confirmed they could move an existing `ecotox.duckdb` to the device, which made (a′) the clean choice and removed need for any snapshot artifact. Added release-match gate (baseline's `ecotox_release` must equal DB release metadata) and `cli_warn` (not abort) when DB is absent.

---

## 4. Cross-check gate — permanent home

| Option | Description | Selected |
|--------|-------------|----------|
| (a) `dev/lifestage/validate_36.R` only | No recurring CI enforcement | |
| (b) `testthat` test at `tests/testthat/test-eco_lifestage_data.R` | CI-enforced forever; pure CSV read | |
| (c) Inline `stopifnot()` in `.eco_lifestage_derivation_map()` | Too aggressive — blocks package load on bad CSV | |
| (d) (b) + (a) combo | CI enforcement + phase-verifiable artifact | ✓ |

**User's choice:** (d)

**Follow-up — force-rebuild path concern:**

User asked whether force-rebuild (non-github-artifact path) would fail because of missing tables or support scripts. Assistant verified via code read (`R/eco_lifestage_patch.R` lines 824-870) that `.eco_lifestage_materialize_tables()` already handles missing-derivation rows gracefully — rows land in `lifestage_review` with `review_status = "needs_derivation"`, no abort.

Deferred to Phase 37: `cli_alert_info` on rebuild paths surfacing quarantined `needs_derivation` rows to end-users.

---

## 5. Future-release refresh strategy

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Manual dev-script trigger | Curator in loop; no silent API dependency | |
| (b) Auto-detect release change in `.eco_patch_lifestage(refresh="auto")` | Silent live API dependency; undermines source-backed guarantee | |
| (c) Out of scope for Phase 36 | Leaves next ECOTOX release with no path | |
| (d) (a) + document in `dev/lifestage/README.md` | Curator-in-loop + future-proofed docs | ✓ |

**Sub-question — refresh script failure mode on derivation gaps:**

| Option | Description | Selected |
|--------|-------------|----------|
| (i) Hard-fail with `cli_abort` | Forces derivation authoring before baseline commit | |
| (ii) Warn + write baseline, surface gaps in proposals file | Curator commits baseline first, derivation second | |
| (iii) Warn + write both CSVs with auto-suggested derivations | Would be silent backstop (contradicts Area 1) | initially selected, corrected to (ii) |

**User's choice:** (d) + corrected (iii) → the suggestion-only pattern from Area 1

**Notes:** Initial "iii" selection was clarified with the assistant. User's actual intent was: auto-suggestions written to a **separate staging file** (`dev/lifestage/derivation_proposals.csv`), not directly into committed `lifestage_derivation.csv`. Curator reviews/edits the proposals, manually promotes vetted rows into the committed CSV, then repatches via `.eco_patch_lifestage(refresh = "baseline")`. This preserves Area 1's no-silent-backstop decision.

---

## Claude's Discretion

- Exact structure/naming inside `dev/lifestage/` directory (script filenames, proposal schema columns beyond the 5 required)
- Testthat file organization (single file vs split assertions)
- CLI output formatting for verification and refresh scripts
- Whether to include the 3 re-resolved rows' unresolved status in validate_36.R's report as a visible diff

## Deferred Ideas

- **Phase 37:** `cli_alert_info` on rebuild paths surfacing quarantined `needs_derivation` rows to end-users
- **Future milestone (v2.5+):** GO (Gene Ontology) provider support for microbial growth-phase terms
- **Future milestone:** `ECOX-01` automated ontology version tracking and update detection
