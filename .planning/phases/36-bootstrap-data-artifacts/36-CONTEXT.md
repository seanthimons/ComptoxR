# Phase 36: Bootstrap Data Artifacts - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `inst/extdata/ecotox/lifestage_baseline.csv` and `inst/extdata/ecotox/lifestage_derivation.csv` complete, internally consistent, and permanently gated for cross-check integrity. Close existing coverage gaps (7 resolved-but-underivable keys, 1 cross-ontology contamination), add a CI-enforced cross-check test, and document a manual refresh path for future ECOTOX releases.

Out of scope: expanding the canonical ontology set beyond UBERON/PO/S11; rebuild-path UX hints (deferred to Phase 37); any backstop that auto-classifies without curator review.

</domain>

<decisions>
## Implementation Decisions

### Cross-check gap remediation
- **D-01:** Hand-author derivation rows for the 6 legitimate missing keys: `S11:S1116` (adult), `S11:S1122` (egg), `S11:S1106` (embryo), `S11:S1128` (larva), `PO:0000055` (bud/inflorescence), `PO:0009010` (seed). Add 7th row if re-resolution of the `GO:0040007` terms (D-03) produces a mappable ID.
- **D-02:** No regex backstop. `lifestage_derivation.csv` is curator-authored only. Any automation of harmonized-category assignment must flow through a staging-file review, never direct commit.

### Cross-ontology contamination (`GO:0040007`)
- **D-03:** Re-resolve the 3 contaminated rows ("Exponential growth phase (log)", "Lag growth phase", "Stationary growth phase") via the Phase-35 prefix-filtered `.eco_lifestage_resolve_term()`. Replace the 3 rows in `lifestage_baseline.csv` with the fresh resolution output.
- **D-04:** Expected outcome is `unresolved` — UBERON/PO/S11 do not cover microbial growth phases. If any provider surprise-matches, that candidate becomes a new derivation key subject to normal curator review.
- **D-05:** Targeted dev-script replacement — do not regenerate the full 139-row baseline.

### ECOTOX completeness check
- **D-06:** Criterion 1 verification = live anti-join in the Phase 36 dev script between `DISTINCT description` from `lifestage_codes` (via `.eco_connection()`) and `org_lifestage` in `lifestage_baseline.csv`.
- **D-07:** Release match gate — the script reads `ecotox_release` from baseline and compares against DB release metadata. Mismatch triggers `cli_abort` ("baseline is for a different release — regenerate or update DB"). DB absent triggers `cli_warn` and graceful skip (Phase 36 verification requires a DB; future contributors may not have one).
- **D-08:** No committed snapshot artifact. The DB is the source of truth for completeness.

### Cross-check gate — permanent home
- **D-09:** Permanent gate = `testthat` test at `tests/testthat/test-eco_lifestage_data.R`. Pure CSV read + anti-join. No network or DB dependency. CI-safe.
- **D-10:** Test assertions: (1) every baseline row with `source_match_status == "resolved"` has a matching `(source_ontology, source_term_id)` in `lifestage_derivation.csv`; (2) `lifestage_derivation.csv` has exactly 5 expected columns (`source_ontology`, `source_term_id`, `harmonized_life_stage`, `reproductive_stage`, `derivation_source`); (3) `lifestage_baseline.csv` has exactly the 13 columns defined in `.eco_lifestage_cache_schema()`.
- **D-11:** Phase 36 verification script = `dev/lifestage/validate_36.R` — invokes the testthat test (or re-runs equivalent checks with verbose output) plus the completeness anti-join (D-06). Pattern consistent with `dev/lifestage/validate_34.R` and `validate_35.R`.

### Future-release refresh strategy
- **D-12:** No auto-rebuild inside `.eco_patch_lifestage()`. New ECOTOX releases are handled exclusively via a manual `dev/lifestage/refresh_baseline.R` script run by the package maintainer.
- **D-13:** Refresh script writes updated `inst/extdata/ecotox/lifestage_baseline.csv` directly (live resolution via existing `.eco_lifestage_resolve_term()`).
- **D-14:** Auto-suggested derivation rows for new unseen `source_term_id`s are written to `dev/lifestage/derivation_proposals.csv` — **never** directly into committed `lifestage_derivation.csv`. Curator reviews, edits, and manually promotes approved rows.
- **D-15:** Refresh procedure documented in `dev/lifestage/README.md` (new file or append) covering: when to run, prerequisites (live API access, DB present), how to review `derivation_proposals.csv`, promotion workflow, repatch via `.eco_patch_lifestage(refresh = "baseline")`.
- **D-16:** Refresh script emits `cli_warn` (not `cli_abort`) on derivation gaps — curator controls pacing of baseline commit vs derivation commit.

### Claude's Discretion
- Exact structure/naming inside `dev/lifestage/` directory (validate_36.R, refresh_baseline.R, proposal schema columns beyond the 5 required)
- Testthat file organization (single file vs split assertions)
- CLI output formatting for verification and refresh scripts
- Whether to include the 3 re-resolved rows' unresolved status in the validate_36.R report as a visible diff

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Implementation Plan
- `LIFESTAGE_HARMONIZATION_PLAN2.md` — v2.4 source-backed resolution plan (active plan)

### Key Source Files
- `R/eco_lifestage_patch.R` — Shared helper layer (993 lines). Specifically:
  - `.eco_lifestage_cache_schema()` §line 8 — 13-column baseline schema reference
  - `.eco_lifestage_dictionary_schema()` §line 27 — dictionary schema
  - `.eco_lifestage_baseline_path()` §line 92 — locates committed baseline CSV
  - `.eco_lifestage_derivation_path()` §line 112 — locates committed derivation CSV
  - `.eco_lifestage_derivation_map()` §line 253 — reads + validates derivation CSV
  - `.eco_lifestage_resolve_term()` — orchestrates OLS4 + NVS + ranking (used by refresh script)
  - `.eco_lifestage_materialize_tables()` §line 775 — rebuild path with quarantine logic for missing-derivation rows
- `R/eco_connection.R` §line 17 — `.eco_connection()` resolves `ecotox.duckdb` path via `tools::R_user_dir("ComptoxR", "data")`
- `R/eco_functions.R` — `.eco_enrich_metadata()` runtime join (Phase 38 target)
- `inst/extdata/ecotox/lifestage_baseline.csv` — 139-row committed baseline (target of updates in D-01/D-03)
- `inst/extdata/ecotox/lifestage_derivation.csv` — 47-row committed derivation map (target of D-01 additions)

### Existing Dev Scripts (pattern reference)
- `dev/lifestage/validate_34.R` — Phase 34 verification script (pattern for validate_36.R)
- `dev/lifestage/validate_35.R` — Phase 35 validation script (all 14 helpers)

### Test Files
- `tests/testthat/test-eco_lifestage_gate.R` — Existing v2.4 patch pipeline tests (leave as-is)
- `tests/testthat/test-eco_lifestage_data.R` — **New** file for permanent cross-check gate (D-09)

### Prior Phase Context
- `.planning/phases/34-teardown/34-CONTEXT.md` — Phase 34 decisions (teardown complete, DB purge path confirmed)
- `.planning/phases/35-shared-helper-layer-validation/35-CONTEXT.md` — Phase 35 decisions (NVS/OLS4 resilience, OLS4 prefix post-filter, BioPortal deferred)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.eco_lifestage_derivation_map()` — already reads `lifestage_derivation.csv` and returns a tibble; the testthat gate can consume it directly or read raw CSV (pure read is cheaper and avoids runtime coupling).
- `.eco_lifestage_resolve_term()` — drop-in for the refresh script; handles OLS4 prefix filter + NVS failure resilience per Phase 35 fixes.
- `.eco_connection()` — canonical DB path resolver for the completeness check.
- Dev script pattern from Phase 34/35 (`validate_NN.R`) — consistent structure for `validate_36.R`.

### Established Patterns
- `tools::R_user_dir("ComptoxR", "data")` for DuckDB location (not repo-local).
- `cli::cli_abort` / `cli::cli_warn` / `cli::cli_alert_info` for user-facing messages throughout v2.4 code.
- `readr::read_csv(..., show_col_types = FALSE)` for CSV reads.
- Schema defined via tibble factory function (`.eco_lifestage_*_schema()`) — use these as the source of truth for column expectations in the testthat gate.

### Integration Points
- **Commit-time gate:** `tests/testthat/test-eco_lifestage_data.R` — CI-enforced forever.
- **Phase verification:** `dev/lifestage/validate_36.R` — one-shot human-readable report.
- **Future refresh:** `dev/lifestage/refresh_baseline.R` + `dev/lifestage/README.md` — manual curator workflow.
- **Rebuild path robustness:** already handled in `.eco_lifestage_materialize_tables()` (lines 832-844) via `needs_derivation` quarantine — no runtime changes needed this phase.

### Current Data State (as of 2026-04-23)
- Baseline: 139 rows × 13 cols (73 resolved, 66 unresolved); 54 distinct `(source_ontology, source_term_id)` keys among resolved.
- Derivation: 47 rows × 5 cols.
- Cross-check gap: **7 resolved keys with no derivation partner** (4 NVS S11, 2 PO, 1 cross-ontology `GO:0040007`-as-UBERON).
- `ecotox.duckdb` present locally per user confirmation on 2026-04-23.

</code_context>

<specifics>
## Specific Ideas

- Derivation-row curator calls for ambiguous cases need to be captured inline in CSV (`derivation_source` column) — use values like `"baseline_curated_source_id"` (existing pattern) for hand-authored rows; use a distinct marker (e.g., `"curator_review_2026Q2"`) only if the team wants a refresh cohort tag.
- For `PO:0000055` (bud/inflorescence) and `PO:0009010` (seed), harmonized category assignment is a judgment call — flag these in the PLAN.md task for explicit curator sign-off before committing derivation rows. Provisional mapping: bud → Adult (with `reproductive_stage = TRUE`); seed → Egg/Embryo. Revisit if curator disagrees.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 37:** `cli_alert_info` on rebuild paths surfacing quarantined `needs_derivation` rows to end-users — belongs in the rebuild code surface, not Phase 36's CSV-integrity scope.
- **Future milestone (v2.5+):** GO (Gene Ontology) provider support for microbial growth-phase terms. Currently these are accepted as `unresolved`. Revisit if researchers flag microbial studies as a recurring need.
- **Future milestone:** `ECOX-01` automated ontology version tracking and update detection (outside current v2.4 requirement scope).

</deferred>

---

*Phase: 36-bootstrap-data-artifacts*
*Context gathered: 2026-04-23*
