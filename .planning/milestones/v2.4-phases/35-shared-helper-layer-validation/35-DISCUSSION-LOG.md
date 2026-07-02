# Phase 35: Shared Helper Layer Validation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 35-shared-helper-layer-validation
**Areas discussed:** BioPortal adapter gap, NVS failure handling, OLS4 prefix filtering, Validation strategy

---

## BioPortal Adapter Gap

| Option | Description | Selected |
|--------|-------------|----------|
| Create it in Phase 35 | Write .eco_lifestage_query_bioportal() + wire into resolve_term as fallback. Keeps PROV-04 on track. | |
| Validate existing, defer BioPortal | Validate the 14 functions that exist. Move BioPortal adapter creation to a new phase. | ✓ |

**User's choice:** Validate existing, defer BioPortal
**Notes:** User wants Phase 35 to remain purely validation-focused. BioPortal adapter creation goes to a new phase inserted after 35 (before Phase 36).

### Follow-up: Where should BioPortal land?

| Option | Description | Selected |
|--------|-------------|----------|
| New phase after 35 | Insert a phase between 35 and 36 for BioPortal adapter creation + wiring. | ✓ |
| Fold into Phase 39 | Add adapter creation to Phase 39 (Quality Gates). Risks making Phase 39 heavier. | |

**User's choice:** New phase after 35

---

## NVS Failure Handling

**User clarification:** Asked whether NVS failure means curation can't occur. Explanation provided: NVS is one of three provider sources (OLS4 UBERON, OLS4 PO, NVS). If NVS fails, OLS4 still contributes candidates. The real problem is that the current cli_abort in .eco_lifestage_nvs_index() crashes the entire bind_rows() call in resolve_term, throwing away OLS4 results too.

| Option | Description | Selected |
|--------|-------------|----------|
| Fix in Phase 35 | Wrap HTTP call in tryCatch, change abort to warn, return empty tibble. | ✓ |
| Document only, fix later | Log the gap. Defer tryCatch fix to Phase 37 or 39. | |

**User's choice:** Fix in Phase 35

### Follow-up: Should OLS4 get the same treatment?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, wrap OLS4 too | Apply same tryCatch + cli_warn + empty tibble pattern to OLS4 calls. | ✓ |
| No, NVS only | OLS4 is primary provider — if it's down, not enough data to curate. Let it abort. | |

**User's choice:** Yes, wrap OLS4 too

---

## OLS4 Prefix Filtering

| Option | Description | Selected |
|--------|-------------|----------|
| Fix in Phase 35 | Add dplyr::filter checking source_term_id starts with expected ontology prefix. | ✓ |
| Document only | Log the gap. Cross-ontology contamination unlikely to cause ranking errors. | |

**User's choice:** Fix in Phase 35

---

## Validation Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Dev script with live calls | Write dev/ script calling each adapter with known terms, checking output shapes and scoring tiers. | ✓ |
| Code reading + load_all only | Verify via devtools::load_all() + reading function bodies. No network dependency. | |
| Mocked unit tests | Write testthat tests with with_mocked_bindings(). Phase 39 already covers this — might duplicate. | |

**User's choice:** Dev script with live calls

### Follow-up: NVS failure simulation method

| Option | Description | Selected |
|--------|-------------|----------|
| Mock URL to dead endpoint | Temporarily override NVS SPARQL URL to non-existent host, confirm cli_warn fires. | ✓ |
| Use with_mocked_bindings | Mock httr2::req_perform to throw an error for NVS call only. | |
| You decide | Claude picks simplest approach. | |

**User's choice:** Mock URL to dead endpoint

---

## Claude's Discretion

- Dev script naming and structure within `dev/`
- Exact test terms used for live adapter validation
- Order of validation checks in the script
- Whether to test OLS4 failure simulation in addition to NVS

## Deferred Ideas

- BioPortal adapter creation — new phase after 35, before Phase 36
