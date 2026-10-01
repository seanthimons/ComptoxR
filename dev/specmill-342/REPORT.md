# Generic-request adoption rehearsal (#342)

Specmill 0.1.11 is installed in the isolated development toolkit library.
The live ComptoxR request helpers have not been replaced. Issue #342 remains
open; the passing results below establish the staged construction/batching
candidate, not completion of response-decoding and pagination adoption.

## Offline-validation update, 1 October 2026

- Release: [v0.1.11](https://github.com/seanthimons/specmill/releases/tag/v0.1.11).
- Source commit: `d59014365b8b30bde2ce319b5e60d9c3f94fe48f`.
- SHA256 of the committed source tar archive:
  `4b8c8c4dddacc457450a4b55ccb9358194544c2cd568c88b44f373b0adb3ffa0`.
- Installation identity, helper emission/provenance and overwrite protection
  checks pass with the new pin. The request template, helper-provenance,
  batching and pagination source files are unchanged from 0.1.10.
- The new schema-validation acceptance script passes for Swagger 2.0, OpenAPI
  3.0 and 3.1, YAML, scoped findings and the generation gate. Validation uses
  bundled official schemas through jsonvalidate/V8, with no hosted validator.
- Before refresh, the local API-schema audit passed 28 of 31 snapshots. AMOS
  has 17 scoped findings, but none block the currently selected operations.
  Mordred/RDKit now pass after download-time normalization and refresh.

Validation remains enabled. The
[ComptoxR #344](https://github.com/seanthimons/ComptoxR/issues/344) generation
blockers are resolved by download-time normalization and schema refresh. The
Mordred/RDKit endpoint YAML mappings already exist and remain unchanged.

The rehearsal's 1,474-case installed-runtime comparison and twelve upstream
checks below were run at **0.1.10**. They have not been rerun or relabeled as
0.1.11 runtime-adoption evidence. The generation diagnostics, local schema
audit and new validation/provenance logs are in the ignored development artifacts.

## Rehearsal toolkit, 0.1.10

- Release: [v0.1.10](https://github.com/seanthimons/specmill/releases/tag/v0.1.10).
- Source commit: `e293b8d8f28410ccee20959e5c918907ce61a592`.
- SHA256 of `git archive --format=tar` at that commit:
  `24d5e6194c23f2577d9d3e4e6ec155a8a0a02429e5bcfa25a1167bf11ca5b538`.
- All five upstream blockers (#63 through #67) are closed. The pin includes
  their integration commit `40ce8aac66317a3721349d60a65291fda5de709b` and its
  response-policy, batching, pagination, plain-text and retry-policy ancestors.
- The installer verifies the installed version as well as source provenance.

Twelve upstream acceptance scripts passed against this installation:
native-transport, form-transport, authentication, request-controls,
response-policy, response-handling, batching, batching-companion, pagination,
pagination-cursors, pagination-companion and plain-text-transport.

## Candidate and ownership

`stage.R` creates a disposable client from the current committed checkout,
applies the reviewed compatibility patch, and emits the pinned native helper
with its batching companion and original helper provenance. It refuses to
overwrite an existing rehearsal destination. The patch must apply cleanly;
manual review is required after incompatible source changes.

The candidate routes both exported generic helpers through generated request
construction. The adapter preserves existing URL encoding, chemical/body
synthesis, API-key lookup, the all-5xx retry predicate, replayable POST retries
and the previous unbounded timeout. Singleton generic JSON inputs use `I()`
to preserve array encoding through the native transport. Its request-body mock
assertion now checks both the original identifiers and that array marker.

| Definition | Owner and adoption state |
| --- | --- |
| `.ct_request`, emitted decoding/formatting helpers, `.ct_request_batched` | Specmill scaffold; emitted into the disposable candidate only. |
| `.ct_request_build` | Candidate client adapter; preserves historical URL bytes and request controls. |
| `generic_request`, `generic_chemi_request` | Live client-owned facades. Candidate construction/batching changed; execution, response processing and pagination remain client-owned. Full replacement gate is pending. |
| `generic_search_request` | Retain. No direct callers; no additional search-specific transport is needed. |
| `generic_pubchem_request` | Retain. PubChem Fault handling, throttling and User-Agent policy remain client-owned. |
| `safe_tidy_bind` | Retain until generated formatting proves identical ordering, type recovery and query attribution. |
| `is_transient_error` | Retain as the explicitly selected client retry predicate. |
| `parse_delimited_response` | Retain, including its caller in descriptor hooks. |
| `unwrap_collection_envelope` | Retain as compatibility response policy. |

The full focused contract/generic-request/Chemi/hook/PubChem suite passed
against the candidate. Repeat helper emission is byte-identical, provenance
hashes match, emitted code contains no specmill runtime calls, and a mismatched
installed version is rejected. These checks do not establish full-client
generation freshness or whole-file ownership protections after final adoption.

The installed original-versus-candidate comparison passed all **1,474 localhost
cases**, with **zero candidate failures**, all **409 exported signatures**
unchanged, and all **four generic-helper signatures** unchanged. Exact requests,
objects, warnings and errors match outside the verifier's already documented
#337 query/options corrections. The first comparison exposed one malformed-URL
error-call difference. Validating with `curl::curl_parse_url()` before deriving
the transport origin fixed it; the candidate was reinstalled and compared again
against the saved original snapshot. The corrected generic tests also passed.
This result applies to construction/batching adoption only; the existing client
response and pagination code still executes in the candidate.

## Generation blocker

After the Mordred/RDKit refresh, specmill 0.1.11 validates both schemas and
generation has no blocking diagnostics or contract drift. The initial full
freshness check proposed writes to `R/chemi_resolver_lookup.R`,
`R/chemi_resolver_lookupCASRN.R` and `.specmill/manifest.json`. A disposable
generation confirmed that these are the only changed outputs. The resolver
changes update validation-error wording and identify the parameter location;
public signatures and request construction are unchanged. These outputs were
reviewed and applied as #325 freshness maintenance. Mordred/RDKit wrapper output
is unchanged. The hosted-validator and OpenAPI 3.1 coverage blockers from 0.1.10
are resolved; no validation bypass was added.

The resulting full `dev/generate_specmill.R --check` passes. The resolver fixed
contracts, input-validation and chemical-resolution tests pass all 147
assertions. This clears the freshness detour; #342 response-decoding and
pagination adoption remains the next generic-request migration work. Logs are
`/tmp/comptoxr-325-freshness.log` and `/tmp/comptoxr-325-resolver-tests.log`.

## Download normalization, #344

Per the [maintainer update](https://github.com/seanthimons/ComptoxR/issues/344#issuecomment-5933689813),
ComptoxR now repairs the empty Swagger 2.0 `basePath` when persisting downloads.
The public downloader, production freeze and fallback fetch share
`.write_downloaded_schema()`. It sets only an explicitly empty Swagger 2.0
`basePath` to `/`; operation paths and nonempty base paths are preserved. JSON
and YAML are supported. Freeze acquisition hashes the resulting file on disk.

Focused tests cover JSON/YAML repair, unchanged source bytes, existing/missing
base paths, OpenAPI 3.1, malformed input and the mocked public downloader.
Fresh Mordred/RDKit downloads match the upstream hashes in the linked update.
The two frozen files were subsequently refreshed through that shared writer,
with specmill validation and semantic comparison before replacement. Their only
semantic change is `basePath: "/"`; JSON key ordering follows the downloaded
documents. Refreshed SHA256 hashes:

- Mordred: `28903bb5feeb60e8deb4c2640a3b6c5b5f47eff2b26c7500bb35cdf780b14a6a`
- RDKit: `6c5c06424c498e73e831ab00856eea584bdc45a5598da5c33ebab8514f389c2a`

Live production GET requests with ethanol (`CCO`) succeeded with HTTP 200 at
`/api/mordred` and `/api/rdkit`, using `https://hcd.rtpnc.epa.gov` as the origin.
Mordred returned 1,613 headers/values; RDKit returned 1,024 fingerprint values.
Both package wrappers also returned those values with `output = "raw"`.
RDKit's default wide wrapper produced one successful row with 1,034 columns.
Mordred's default wide wrapper produced zero rows: 385 JSON null descriptor
values reach the existing formatter, whose `[[i]] <- NULL` assignments remove
list elements. This response-formatting defect is separate from schema
validation and remains unresolved; raw output preserves the response.

The download-normalization, descriptor-contract and descriptor-SMILES-hook test
files all passed. Probe evidence is in the ignored artifact
`dev/specmill-pilot/artifacts/issue-344-live-results.json`; generation and wrapper
logs are `/tmp/comptoxr-344-{generation,plan,wrappers,raw,tests}.log`.

## Reproduction

Run from the ComptoxR root with the pinned commit available in the source repo:

```sh
Rscript dev/install_specmill.R
Rscript dev/specmill-342/stage.R
Rscript dev/specmill-342/verify.R
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local("dev/specmill-pilot/artifacts/issue-342-rehearsal", filter="^(contract-.*|generic_request|generic_request_edge|generic_chemi_request|pubchem_offline|hooks_stage_server|chemi_search|ct_chemical_list_all_hooks)$", stop_on_failure=TRUE, reporter="summary")'
mkdir -p dev/specmill-pilot/artifacts/issue-342-rehearsal-library
R CMD INSTALL --library=dev/specmill-pilot/artifacts/issue-342-rehearsal-library dev/specmill-pilot/artifacts/issue-342-rehearsal
Rscript dev/specmill-full/verify-runtime.R dev/specmill-pilot/artifacts/before-library dev/specmill-pilot/artifacts/issue-342-rehearsal-library dev/specmill-pilot/artifacts/issue-342-rehearsal-runtime dev/specmill-pilot/artifacts/issue-342-rehearsal-runtime-results.json
```

The first exploratory candidate and its installed library are under
`dev/specmill-pilot/artifacts/issue-342-candidate` and `issue-342-library`.
Focused and upstream logs, validation diagnostics and localhost comparison
evidence are also under that ignored artifacts directory. The comparison uses
the existing installed original-client baseline, not a toolkit-only check.

Rollback requires no runtime-helper changes: those files remain unchanged.
Restore the prior `dev/specmill-lock.json` pin and run `dev/install_specmill.R`
to restore the isolated 0.1.8 toolkit. Dispose only of the rehearsal artifacts
created for this issue. Do not merge the migration while #342's remaining
adoption, freshness, idempotence and ownership checks are unresolved.
