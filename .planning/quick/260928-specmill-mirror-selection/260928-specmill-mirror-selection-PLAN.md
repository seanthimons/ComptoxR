# Plan: restore upstream mirroring under specmill (opt-out selection)

Branch: `feat/specmill-migration-pilot`; everything lands in the single `feat/specmill-hooks-wave` PR. No intermediate PRs.
Pinned specmill: 0.1.8 @ `2df2657b` (`dev/specmill-lock.json`).

## Problem

The legacy flow (`schema-check.yml` → `dev/generate_stubs.R`) mirrored upstream schemas: added endpoints became stubs, removed ones were reflected in the package. The specmill migration broke that without anyone deciding to:

1. **Every `apis/*.yml` uses `selection.include`**, an exact allowlist. In specmill (`R/operations.R:91`), anything outside it is marked `excluded` with reason `Not in service include`. `R/generation.R:1128` also drops that reason from the report, so new upstream endpoints are silently ignored.
2. **`schema-check.yml` still runs the legacy generator** (lines ~200–202, plus the `--check` step). `specmill-maintenance.yml` only verifies that regeneration is a no-op and never adds anything.
3. **`dev/generate_specmill.R:20-26` stops on any diagnostic.** specmill's intended behaviour (see specmill#26 disposition) is to reject the unsupported route and keep generating the rest. In an automated run, one unsupported new endpoint would block every healthy addition.

Goal: specmill's default selection (all operations in the schema), with `exclude` only for routes deliberately skipped. The scheduled workflow regenerates via specmill and opens a PR. Unsupported routes are reported in the PR, not fatal.

## Constraint discovered: schemas are shared across service files

Several schemas feed 2–3 service configs with disjoint allowlists. Removing `include` from one config would re-select the operations owned by its siblings, causing name/file collisions or duplicate wrappers.

| Schema | Service configs |
|---|---|
| chemi-amos-prod | amos-pilot, chemi-amos-prod-full |
| chemi-chet-prod | chemi-chet-prod-full, chemi-chet-prod-rebuild |
| chemi-resolver-prod | chemi-resolver-prod-full, chemi-resolver-prod-rebuild |
| chemi-search-prod | chemi-search-prod-rebuild, search-pilot |
| chemi-services-prod | chemi-services-prod-full, chemi-services-prod-rebuild |
| chemi-toxprints-prod | chemi-toxprints-prod-full, chemi-toxprints-prod-rebuild |
| ctx-chemical-prod | ctx-chemical-prod-full, ctx-chemical-prod-rebuild, ctx-pilot |
| ctx-exposure-prod | ctx-exposure-prod-full, ctx-exposure-prod-rebuild |
| epi-suite-prod | epi-pilot, epi-suite-prod-full |
| (all others) | one config each |

**Rule:** for each schema, exactly one config runs in opt-out mode, the "mirror". Either merge the siblings' `operations:` blocks into the mirror and delete the siblings (preferred: fewer files, one owner per schema), or keep the siblings and add their keys' paths to the mirror's `exclude`. Keep each operation's `name`/`file`/`implementation` unchanged so no wrapper moves.

Check first whether specmill allows a service to have `operations:` entries (overrides) without `include`. `R/operations.R:~735` validates override keys against the inventory, not against `include`, so it should.

## Tasks

### 1. AMOS pilot (first, and proves the approach)

- Merge `apis/amos-pilot.yml` into `apis/chemi-amos-prod-full.yml` (or exclude its paths; see rule above). Drop `selection.include`.
- Add `selection.exclude` (anchored path regexes) for:
  - **The 26 POST routes blocked on specmill#26**: prod schema is Swagger 2.0 with no `consumes`, which specmill rejects as `Ambiguous body media type`. Comment: `# specmill#26: no consumes in prod 2.0 schema; remove when AMOS 3.0 reaches prod`. Full list is in specmill#26. They are the POSTs under `/api/amos/` named `add_*`, `*_keyset_pagination/{limit}`, `*similarit*`, `batch_search`, `analytical_qc_batch_search`, `count_substances_in_ids/`, `dtxsids/`, `mass_range_search/`, `mass_spectra_for_substances/`, `next_level_classification/`, `record_counts_by_dtxsid/`, `spectral_entropy/`, `spectrum_count_for_methodology/`, `substances_for_classification/`, `substances_for_ids/`.
  - **The 6 write routes** `PUT /api/amos/update_*_info/{internal_id}`. Prefer `selection.methods: [GET, POST]` on the service over path regexes.
- Caution: `exclude` matches **paths**, not method+path. Several blocked POST paths also have a GET twin (e.g. `method_keyset_pagination/{limit}`). A path exclude removes both. Check each one. If a GET twin should stay, the plan needs another mechanism: verify in specmill whether a key-level exclude exists; otherwise accept losing the GET until #26 closes, and record it.
- Triage the other not-included operations that would become selected (listed below). For each, either generate, match an existing hand-written wrapper (`implementation: existing`, e.g. `R/chemi_amos_get_pdf.R`, `R/chemi_amos_method_with_spectra.R`, `R/chemi_amos_get_similar_structures.R`, `R/chemi_amos_get_classification_for_dtxsid.R`), or exclude with a reason.
  ```
  GET additional_sources_for_substance/{dtxsid}      GET get_similar_structures/{identifier_type}/{identifier}
  GET analytical_qc_keyset_pagination/{limit}        GET get_substance_file_for_record/{internal_id}
  GET fact_sheet_keyset_pagination/{limit}           GET list_sources_by_record_type/{record_type}
  GET get_classification_for_dtxsid/{dtxsid}         GET method_keyset_pagination/{limit}
  GET get_data_source_info/                          GET method_with_spectra/{search_type}/{internal_id}
  GET get_info_by_id/{internal_id}                   GET product_declaration_keyset_pagination/{limit}
  GET get_ir_spectrum/{internal_id}                  GET record_ids_for_substance/{dtxsid}/{record_type}
  GET get_mass_spectrum/{internal_id}                GET release_notes
  GET get_nmr_spectrum/{internal_id}                 GET safety_data_sheet_keyset_pagination/{limit}
  GET get_pdf_metadata/{record_type}/{internal_id}   GET search_by_text/{substr}
  GET get_pdf/{record_type}/{internal_id}
  POST retrieve_fact_sheets/  POST retrieve_product_declarations/  POST retrieve_safety_data_sheets/
  POST search_for_document_ids/{record_type}
  ```
  (Some of these are already owned by `amos-pilot.yml` and resolve through the merge.)
- Hand-written wrappers already exist for two of the #26 routes: `R/chemi_amos_next_level_classification.R` and `R/chemi_amos_spectral_entropy.R`. Both call `generic_chemi_request()`, which JSON-encodes the body. Leave them hand-owned and don't delete them. Note in the exclude comment that they exist.
- Rehearse: `Rscript dev/generate_specmill.R --plan`. Expected: no `remove`/`protected` actions on existing wrappers; `write` only for newly triaged generated routes; zero diagnostics. Record the plan output alongside the other migration reports.
- `--apply`, then `--check` and `git diff --exit-code` must pass (mirrors `specmill-maintenance.yml`).

### 2. Gate: diagnostics reported, not fatal, in auto mode

- `dev/generate_specmill.R`: add an explicit mode for the scheduled workflow (e.g. `--apply --report-diagnostics <file>`). It writes `plan$diagnostics` / `mapping_diagnostics` / `retained_diagnostics` to a markdown file and continues.
- Keep drift and `protected` actions fatal in every mode: they mean hand-owned output would change.
- Keep the current strict behaviour for `--check` in `specmill-maintenance.yml`. The committed state must still have zero diagnostics, which is exactly why the `exclude` entries exist.
- Add one small test/check that a synthetic diagnostic is reported, not thrown, in the new mode.

### 3. Workflow: `schema-check.yml` runs specmill

- Replace the `generate_stubs.R` generate and check steps with: install pinned specmill (reuse the steps from `specmill-maintenance.yml`: lock read, checkout, `dev/install_specmill.R`, air 0.11.0) → `generate_specmill.R` in the new auto mode → `devtools::document()`.
- Append the diagnostics report to the PR body next to the existing schema diff report.
- Remove or adjust the legacy stub counters in the PR body (`stubs_generated`, etc.).
- Keep the schema download / pretty-print / hash / diff steps as they are.
- Decide whether `generate_tests.R` / `detect_test_gaps.R` are still needed or whether specmill `artifacts = c("wrappers", "tests")` covers them. Don't double-generate tests.
- Verify with `workflow_dispatch` on the branch. Confirm a no-change run opens no PR.

### 4. Removal behaviour (verify, don't assume)

- specmill's plan has a `remove` action (`R/generation.R:~1174`). Confirm when it fires: that a generated wrapper whose operation disappears from the schema is removed, and that hand-owned (`implementation: existing`) files are never removed.
- Rehearse by deleting one generated operation from a scratch copy of a schema and running `--plan`. Document the result. If removal is `protected` or silent, handle it in the gate (task 2) so it appears in the PR.

### 5. Remaining services

Flip one schema at a time, AMOS first. For each schema: consolidate to one mirror config, drop `include`, `methods` filter for writes, triage the newly selected backlog, rehearse `--plan`, apply, then check. Commit per schema. Expect some services to surface specmill parser blockers already known from the proving-ground audit (specmill#26–#29, #31). Each one gets an `exclude` entry with the issue link.

## Done when

- No `apis/*.yml` has `selection.include`, and each schema has exactly one mirror config.
- Every `exclude` entry carries a reason (issue link or "write route").
- `specmill-maintenance.yml` passes: zero diagnostics, regeneration is a no-op.
- `schema-check.yml` runs specmill. A dispatch run with no upstream change opens no PR, and a run with a new endpoint would produce a wrapper diff plus a diagnostics section.
- The legacy `generate_stubs.R` path is no longer called from CI. Deleting it is a separate cleanup unless trivially safe.

## Follow-up tied to specmill#26

AMOS dev/staging already serves OpenAPI 3.0.3 (`https://cim-dev.sciencedataexperts.com/api/amos/swagger.json`). There, all 26 routes declare `requestBody.content`: 21 `application/json` and 5 `multipart/form-data` with `file: {type: string, format: binary}`, which also clears specmill#27's nested-file defect. When prod switches, delete the 26 exclude lines and regenerate. Breaking change to expect: `batch_search` and `analytical_qc_batch_search` rename body field `ids` → `identifiers`.
