# Generic-request adoption, #331 and #342

The live checkout now uses Specmill 0.1.11 request construction, JSON/text/binary
and delimited decoding, batching, and the emitted pagination loop. Client policy
preserves the exported facades, URL encoding, chemical synthesis, authentication,
server precedence, httr2 execution errors, response observation and result formatting.
No runtime dependency on Specmill was added.

The reviewed pin is `d59014365b8b30bde2ce319b5e60d9c3f94fe48f`, with source-archive
SHA256 `4b8c8c4dddacc457450a4b55ccb9358194544c2cd568c88b44f373b0adb3ffa0`.
All five upstream ports, Specmill #63 through #67, are included. The 13 upstream
acceptance scripts passed against this isolated 0.1.11 installation, including
response/retry policies, emitted companions, plain-text transport and offline
schema validation.

## Ownership and reproduction

`emit.R` derives `R/z_specmill_request.R` from the pinned scaffold with batching
and pagination selected. Its only implementation adjustment exposes the native
response decoder as `.ct_request_decode()` so the existing httr2 execution path
can preserve errors and observation. Companion exports become internal, and
trailing whitespace is removed. The untouched upstream baseline and settings
remain in `.specmill/helpers/.ct_request.json`.

| Definitions | Owner |
| --- | --- |
| `.ct_request`, `.ct_request_decode`, emitted decoding/formatting helpers and companions | Reviewed Specmill scaffold, reproduced by `emit.R` |
| `generic_request`, `generic_chemi_request`, `.ct_request_build`, `.ct_request_pages`, response compatibility policies | Client facades and policy; reproduced by `compatibility.patch` against the recorded base commit |
| `generic_search_request` | Retain; no direct callers |
| `generic_pubchem_request` | Retain; PubChem Fault, throttle and User-Agent policy |
| `safe_tidy_bind`, `unwrap_collection_envelope` | Retain; collection ordering, null/type cleanup and attribution |
| `is_transient_error` | Retain; explicitly selected 429/all-5xx retry predicate |
| `parse_delimited_response` | Retain; descriptor-hook caller and legacy malformed-table errors |

The entire two runtime files remain client-owned, outside manifest wrapper
ownership. The emitter rejects a customized file unless its exact reviewed
SHA256 is supplied. `verify.R` checks freshness, baseline hashes, repeated
emission, overwrite refusal, explicit adoption and installed-version rejection.
CI runs this verifier and the focused runtime/contract suite.

`adoption.json` records the base commit, toolkit source, adopted file hashes,
owners and verification summary. `stage.R` archives that base and applies the
binary-capable patch, including the three corrected wrappers, YAML, documentation
and frozen contract fixture. Facade, native helper, YAML and fixture reproduction
were checked byte-for-byte. Ordinary wrapper regeneration preserves both helpers.

## Reviewed ChET corrections

The three public paginated wrappers now default to `page = 1` and select
`chet_page` explicitly. Resolver Spring Boot pagination keeps `page_size`.
ChET counts use a bare collection; chemical/reaction databases extract `data`.
Iteration stops on an empty page. Manual single-page output remains unchanged.
These are the three accepted exported-default changes from the #331 review.
The generation gate accepted exactly those three `page` drifts once; subsequent
checks retain the normal strict drift policy.

`chemi_chet_chemicals_image()` now decodes its multi-format response from the
actual Content-Type. `magick` is now an Imports dependency; PNG/SVG convert to
images and PDF stays raw. Live checks also exposed the old image route as a 404.
The wrapper now uses `/api/chet/chemicals/{chemical_id}/image`, matching the
schema and the live service. The public signature is unchanged.

## Verification

- Focused contract, generic/Chemi, hooks, search and offline PubChem tests pass.
- Localhost ChET checks pass for two full pages followed by an empty page,
  manual pagination, PNG/SVG/PDF, and successful-page recovery with observation
  of the failed response. The PNG fixture is a valid generated one-pixel image;
  all image checks require conversion to succeed.
- Installed-client comparison passes all 1,474 cases, with zero candidate
  failures, all four generic-helper signatures unchanged and 409 exported
  signatures reviewed. Three exported page defaults changed. Requests, objects,
  warnings and errors match outside the previously reviewed #337 corrections
  and the nine explicitly asserted ChET cases.
- Generation freshness, repeat-generation idempotence, emission/provenance and
  whole-file ownership checks pass. The retained ToxPrint diagnostic is unchanged;
  its review now fingerprints both adopted helper files.

The comparison reuses the saved original-client baseline from the earlier
0.1.10 rehearsal and executes the installed adopted client against localhost.
Its assertions and report were evaluated against both saved snapshots. Full
results and logs remain in ignored artifacts; the report SHA256 is recorded in
`adoption.json`. No production row-count verification is claimed. Production pagination remains tracked in #331. PR completion and merge remain
controlled by #325. The published runtime summary is `runtime-results-summary.json`;
the full ignored report checksum remains in `adoption.json`.

## Targeted image verification, 1 October 2026

`magick` 2.9.1 was installed from CRAN source. Its native dependency, ImageMagick
7.1.2-32, was built from the official release under
`~/.local/opt/imagemagick-7.1.2-32`; no administrator access was needed. The R
installation links that user-local library without requiring session environment
variables. Package users need the normal ImageMagick system dependency.

`probe-image.R` checked the actual package wrapper for ChET chemical ID 1, using
the default production API root. All three requests returned HTTP 200:

| Format | Response media | Result |
| --- | --- | --- |
| PNG | image/png | magick-image, 346 x 195 |
| SVG | image/svg+xml | magick-image, 343 x 194 |
| PDF | application/pdf | 3,069 raw bytes with a PDF signature |

Evidence is in `image-results.json`. The targeted image-wrapper contract and
localhost adoption tests passed with magick installed. The earlier 1,474-case
comparison predates this dependency/route correction; it was not rerun or
relabeled. This follow-up verified only image functionality and generation
freshness, with no bulk production pagination scan.

Run from the package root:

```sh
Rscript dev/install_specmill.R
Rscript dev/specmill-342/verify.R
Rscript dev/generate_specmill.R --check
Rscript dev/specmill-342/stage.R
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(contract-.*|generic_request|generic_request_edge|generic_chemi_request|pubchem_offline|hooks_stage_server|chemi_search|ct_chemical_list_all_hooks|specmill_adoption)$", stop_on_failure=TRUE, reporter="summary")'
```

`stage.R` refuses an existing destination. Installed-client comparison uses
`dev/specmill-full/verify-runtime.R`; supply original and candidate library paths,
output directory and report path. The optional `COMPTOXR_BASELINE_SNAPSHOT` and
`COMPTOXR_CANDIDATE_SNAPSHOT` variables reuse saved comparison snapshots.

Run `Rscript dev/specmill-342/probe-image.R` explicitly to repeat the three live
format checks. Routine tests stay on localhost.

Rollback restores the files in `compatibility.patch` from the recorded base,
removes the new native helper/baseline and restores the previous ToxPrint review.
The 0.1.11 toolkit pin can remain. No credentials, user configuration, databases
or upstream schemas change as part of this adoption.
