# Retrospective: v2.4 Source-Backed Lifestage Resolution

**Milestone:** v2.4
**Completed:** 2026-05-05
**Phases:** 34-39, including 36.1 and 36.2
**Plans:** 12/12 complete

## Summary

v2.4 corrected the v2.3 lifestage strategy by replacing regex-first classification and cosmetic ontology IDs with a source-backed patch seed workflow. The milestone shipped deterministic installed lifestage data, maintainer-facing provenance and curation artifacts, in-place patch support, runtime API finalization, and mocked provider tests.

## What Worked

- The teardown-first approach removed the wrong v2.3 implementation before layering in the source-backed path.
- Inserted phases 36.1 and 36.2 were useful: they forced unresolved coverage analysis and semantic adjudication before runtime integration.
- The patch seed decision made the package deterministic while preserving maintainer source/provenance workflows in `dev/lifestage/`.
- Mocked provider tests gave coverage for OLS4, NVS, and BioPortal behavior without live network dependence.

## What Was Hard

- ECOTOX source blanks can look like dictionary failures in enriched output; the join audit was needed to separate source-data absence from implementation defects.
- Early artifact naming around baseline/derivation implied installed runtime data; the final package surface needed a cleaner patch seed boundary.
- Planning traceability drifted: TEAR and PROV rows in the active requirements file stayed unchecked after phases 34 and 35 completed.

## Decisions To Carry Forward

- Keep installed runtime data deterministic unless a user explicitly opts into live refresh behavior.
- Keep maintainer provenance artifacts outside the installed runtime path unless they are deliberately promoted.
- Treat blank ECOTOX `tests.organism_lifestage` as a separate source-data enrichment problem, not as dictionary coverage debt.
- Reconcile requirements traceability as part of phase completion, not only at milestone closeout.

## Follow-Up Candidates

- Plan a focused source-data enrichment milestone for blank ECOTOX lifestage rows if the missing lifestage count matters for downstream analyses.
- Decide policy for the quarantined `lifestage_review` rows.
- Revisit the older stub-generation schema description todo during the next pipeline-oriented milestone.
