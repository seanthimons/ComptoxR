# AMOS released v0.1.41 migration

This work targets ComptoxR PR345. It leaves the root lock, helper, manifest,
progress ledger and handoff unchanged. Root integration must teach the shared progress script to map this additional derivative through `provenance.json` to the unchanged canonical operation keys, then append
`apis/chemi-amos-direct-reads.yml` to `specmill.yml` and regenerate ownership from
released v0.1.41, adopting only the exact hashes of the three new generated files if needed. Do not copy an isolated manifest into the root checkout.

## Completed operations

Three new public bindings use unchanged canonical GET declarations:

- `chemi_amos_additional_sources_for_substance(dtxsid)` calls
  `/api/amos/additional_sources_for_substance/{dtxsid}`.
- `chemi_amos_get_pdf_metadata(record_type, internal_id)` calls
  `/api/amos/get_pdf_metadata/{record_type}/{internal_id}`.
- `chemi_amos_get_substance_file_for_record(internal_id)` calls
  `/api/amos/get_substance_file_for_record/{internal_id}`.

Read-only production probes returned 200 for all three. DTXSID7020182 has ChemExpo
and Wikipedia links. Fact Sheet FS-10313 has a populated PDF name and metadata
rows, and its substance file is a real 5665-byte Excel workbook. `live.rds` stores
request paths, status, media and response bytes without credentials. These
controls demonstrate these records, not every possible record or record type.

The 77 canonical operations are enumerated in `inventory.json`. Before this work,
61 had native bindings and 16 were unbound. These three bring the candidate
canonical coverage to 64/77, pending root integration and ownership registration.
AMOS metadata/version reads are already bound but absent from the canonical
snapshot and excluded from this denominator.

## Reviewed source

`schema/chemi-amos-reviewed-native.json` is a separate self-contained Swagger2
subset used by `amos-pilot`, `chemi-amos-prod-full` and the new direct-read service.
The existing five-operation OAS3 reviewed-read subset and provenance stay intact.
Canonical snapshots remain verbatim.

`bundle.R` reproduces the derivative and `provenance.json` records the SHA256
inputs/output, complete operation list, definition closure and evidence. All 56
other operation objects and all reachable definitions are copied unchanged.
Three operation objects differ:

- The two existing reviewed path corrections declare the actual required string
  placeholders for get_similar_structures and list_sources_by_record_type.
  They add no enum or constraint. The existing config corrections remain intact.
- dtxsids has an empty canonical responses object, which formal Swagger2 validation
  rejects. The derivative supplies a 200 JSON response description supported by
  existing production/native fixtures. This materializes the existing response_correction, including produces application/json, and removes the now redundant config correction. Its request declaration is unchanged.

No OAS3 requestBody is inserted into Swagger2. No input body, enum, server origin or response schema is invented; the only media declaration is the already-reviewed JSON response correction. The canonical missing server origin stays
missing in this derivative; current resolver keys and explicit production request
mappings continue to own routing. Existing service IDs, operation keys, wrapper
names/files/formals and controls are preserved.

## Held operations

All 13 held operations and reasons appear individually in `inventory.json`:

- POST `/api/amos/batch_search` and `/api/amos/analytical_qc_batch_search` retain
  `chemi_amos_batch` and `chemi_amos_analytical_qc_batch`. Their old generic Chemi
  payload/gate differs from the corrected service body. Previously archived
  minimal and populated requests returned HTTP500. Changing to identifiers and
  accepting a workbook without positive service evidence would change behavior.
  Prior evidence is in `amos-remaining-live-review.rds` and
  `amos-full-body-live-review.rds` in the parent directory.
- Five POST uploads, add_aqc_spectrum and add_new_fact_sheet/method/
  product_declaration/safety_data_sheet, remain unbound. Canonical definitions
  put files inside JSON body schemas and do not establish valid multipart
  contracts. The reviewed staging snapshot omits these operations.
- Six PUT updates, update_analytical_qc_pdf_info/fact_sheet_info/method_info/
  nmr_spectrum_info/product_declaration_info/safety_data_sheet_info, remain
  unbound. Canonical operations declare only internal_id and no submitted body;
  the reviewed staging snapshot omits these operations.

No production/staging writes, uploads, sessions or mutation probes were made.
This is existing source-contract work, recorded on
[Specmill #27](https://github.com/seanthimons/specmill/issues/27#issuecomment-6254000651),
not a new generator gap. Related media history remains on Specmill #26.

## Reproduction

Run from the package root with the verified toolkit library installed by
`dev/install_specmill.R`. Every R command must use persistent disk TMPDIR:

```bash
mkdir -p /home/sxthi/.cache/comptoxr-amos-v41/tmp
export TMPDIR=/home/sxthi/.cache/comptoxr-amos-v41/tmp
Rscript dev/specmill-rebuild/amos-v41/bundle.R
Rscript dev/specmill-rebuild/amos-v41/generate.R apply
Rscript dev/specmill-rebuild/amos-v41/generate.R check
Rscript dev/specmill-rebuild/amos-v41/verify.R
# Optional, repeats only the three read-only production GET controls:
Rscript dev/specmill-rebuild/amos-v41/probe.R
```

`generate.R` uses an isolated disk-backed copy and full `validation=TRUE` for the
whole client. It copies only scoped AMOS generated output back and independently
checks every isolated owner hash. Full validation includes every source in the
isolated full project config; unrelated retained-source warnings stay visible.
Root manifest bytes are never changed. `verify.R` checks source provenance,
existing public signatures, scoped documentation freshness and AMOS regressions.
No full package check or full client test suite is claimed for this family-only
iteration.

## Verification results

Official released Specmill v0.1.41 provenance matches source
`05862bee1804806cea157ff1962300d741516301` and the committed archive checksum.
Full validated generation passes all 28 selected schema documents, including the
new derivative. Operation, mapping, retained-output and drift diagnostics are
empty. The four pre-existing Mordred/WebTEST hook-route warnings remain visible.

The independent ownership report checks all 593 output hashes and proves that
all 590 existing ownership identities and output hashes are unchanged. The root
manifest remains untouched. The first emission added only three wrappers; the
final apply refreshed only the isolated manifest after export registration.

The clean regression replay passes 1,650 assertions with zero failures, errors,
warnings or skips, including the 228 direct-read assertions. All 62 existing
public signatures match the baseline. Documentation and exports for the three
new bindings come from roxygen in a minimal package copy. Final generated-wrapper
production GETs return meaningful links, PDF metadata, and a workbook containing
DTXSID7020182; its worksheet has 20 chemical rows plus a header.

`tests.json`, `direct-tests.json`, `ownership-verification.json`, the generation
reports, `generated-live.rds`, and final text logs hold the portable results.
Earlier rejection and test-harness failures remain under `logs/`; the clean
reruns supersede them. No full package check, full-client test suite, examples or
vignettes were run in this AMOS iteration.

Final independent full `validation=TRUE` check passes: all 593 owned outputs are unchanged, the isolated manifest needs no update, and every owned output hash matches. All 590 pre-existing owner identities and hashes remain identical. See `generation-check.json` and `logs/generation-check-final.txt`.

## Root adoption

Root adoption uses official v0.1.42 and validates all selected sources. The fresh production download and retrieval metadata are retained in `amos-prod-current.json` and `amos-prod-retrieval.json`. Every operation object matches the archived canonical source. Two example decimals changed, with no declaration changes. The archived canonical remains unchanged. Root progress now maps the reviewed derivative through its recorded canonical identities.
