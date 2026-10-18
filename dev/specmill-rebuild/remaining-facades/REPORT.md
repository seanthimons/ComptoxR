# Remaining legacy facades, PR345

Base is `341b8526`. This wave selects one endpoint, POST `/api/resolver/safety-flags`, and leaves five public wrappers unchanged. It does not complete the full PR345 migration. The root pin, request helpers, parent-owned mappings, progress ledger and PR checkpoint are outside this wave.

The toolkit is released Specmill 0.1.41, source `05862bee1804806cea157ff1962300d741516301`, git-archive SHA256 `70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`. The archive checksum was independently reproduced from the local source repository. Generation uses the isolated installed release, with no active library modification. The committed root pin remains parent-owned.

## Selected calculation

`chemi_resolver_safety_flags_bulk` stays in `R/chemi_resolver_safety_flags.R`, with the original 17 optional formals and experimental lifecycle. The old helper interpreted `additionalProps` as chemical identifiers, nested the other Chemical fields under options, and ignored `request.filesInfo`. Its body did not match the declared Chemical array.

The first localhost replay exposed the shared decoder's deliberate 401 conversion to `specmill_call_error`. A supported pure response validator now calls `httr2::resp_check_status` for received errors, preserving the old typed 401/404/500 conditions without changing the helper or executor. `logs/first-native401-failure.log.gz` retains the failed replay.

The new native mapping projects the public fields into one Chemical object inside an array, with the existing generated body validator. It evaluates the old option fields before the primary input, preserves the original empty-input error, and leaves the ignored file argument lazy. There is no implicit identifier-resolution workflow and no file upload support. The body correction is intentional; request bytes are not claimed to match the invalid old body.

The canonical resolver schema is unchanged. An explicit `exclude_parameters: ["files[]", "request"]` selects the independently verified JSON calculation alternative. On production and staging, identifier-only input `[{"sid":"DTXSID7020182","additionalProps":{"source":"ComptoxR"}}]` returned HTTP200 with nonempty flags. `safety-live.rds` retains request inputs and raw responses; `probe-safety.R` reproduces this public calculation only.

The initial controls mixed that BPA identifier with formaldehyde SMILES. Their artifacts are retained as superseded inconsistent inputs and are not the evidence for adoption. The corrected identifier-only controls also underpin the public example. See the [upstream correction](https://github.com/seanthimons/specmill/issues/28#issuecomment-6253544013).

## Held facades

- `chemi_resolver_getpubchemlist`, POST `/api/resolver/getpubchemlist`, resolver schema. The old request returns 400; a declared flat Chemical request with explicit required query controls returns 200 with nonempty items on both services. The source uses page/itemsPerPage and total/items, while the old helper actually pages a body offset and reads records/totalRecordsCount. The existing public signature exposes none of the five required source query controls. A native candidate preserving the signature rejects its hidden pager parameter. Pre must run once before paging, including skips and partial state updates. The exact rejection and mapping are retained in `held-config-results.rds` and `pubchem-held.yml`. [Specmill #173 reproduction](https://github.com/seanthimons/specmill/issues/173#issuecomment-6253439696).
- `chemi_stdizer_groups_recursive(id)`, GET `/api/stdizer/groups/{id}/recursive`, standardizer schema. Native permissive `any` fan-out reproduces #166. Independently, the old facade builds `/groups/recursive/{id}`, which returned 404 for an advertised staging group; the canonical path returned 200 with recursive data. The corrected path remains held with the generation gap. [Specmill #166 reproduction](https://github.com/seanthimons/specmill/issues/166#issuecomment-6253439931). No private PR167 code was adopted.
- `chemi_stdizer_groups_bulk`, POST `/api/stdizer/groups`, and `chemi_alerts_groups_bulk`, POST `/api/alerts/groups`. Canonical binary-query and nested-request declarations remain unresolved. The old helper constructs Chemical payloads rather than LibraryGroup bodies and drops some exposed request fields. Held JSON-only generated projections preserve formals, original empty-primary conditions and lazy unused arguments. They are exercised only on localhost; they establish serialization, not a server mutation/upload contract. Their source bytes are in `generated-held/`, outside package runtime. [Specmill #28 current reproduction](https://github.com/seanthimons/specmill/issues/28#issuecomment-6253351009).
- `chemi_stdizer_bulk`, POST `/api/stdizer`, standardizer schema. Every call reaches the old helper without query or chemicals and therefore errors before transport, including when all four file/options arguments are supplied. Three offline cases record this in `stdizer-input-proof.rds`. Its binary/nested query declaration has no declared JSON body. Enabling a working standardization workflow would require an unsupported contract and a behavioral decision; none was invented. It shares the existing #28/#31 hold.

A final read-only service declaration review is retained in `group-source-review.rds`. Production standardizer OpenAPI 3.1.0 still declares required binary `files[]` and nested `request` query inputs on group creation. Production alerts docs returned 502. Both staging docs returned 200 but do not declare the corresponding base group POST. These observations do not justify a replacement mutation contract. `probe-group-sources.R` reproduces only those documentation GETs.

All canonical sources remain verbatim. No alternate source snapshot or source correction is promoted. No group POST or upload was performed on production or staging. `canonical-blockers.rds` records the initial canonical-source rejections, including safety before its JSON alternative was established.

## Verification and reproduction

All remaining R processes use a dedicated persistent `TMPDIR` under `/home/sxthi/.cache/comptoxr-remaining-facades`. The unrelated shared tmpfs exhaustion interrupted an earlier disposable run; its raw failure log is retained in `logs/full-generation-enospc.log.gz`. Interrupted runs are not counted as passes. Raw logs are committed as lossless `.log.gz` artifacts.

Run from the project root with the isolated official toolkit path:

```sh
export TMPDIR=/home/sxthi/.cache/comptoxr-remaining-facades/tmp
export SPECMILL_LIBRARY=/tmp/chet-specmill41-library
Rscript dev/specmill-rebuild/remaining-facades/verify.R
Rscript dev/specmill-rebuild/remaining-facades/verify-ownership.R
Rscript dev/specmill-rebuild/remaining-facades/verify-held.R
Rscript dev/specmill-rebuild/remaining-facades/verify-groups.R
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(native_remaining_facades|native_static_media|chemi_resolver_chemical_resolution)$", stop_on_failure=TRUE)'
```

`verify.R` requests whole-client `validation = TRUE` and the same wrapper/test artifacts as the maintenance generator. Archived invalid source findings remain visible; they are not bypassed. `verify-held.R` asserts both actual release rejections. `verify-groups.R` creates a minimal temporary R/schema project, regenerates both held projections, compares exact bytes, then checks freshness. It never calls a service. Public live probes are separate scripts.

The runtime suite uses real localhost HTTP and normal httr2 error handling. It compares frozen legacy definitions with the candidate for successful results, NULL slots, empties, malformed JSON and received 401/404/500 conditions; checks the actual JSON bodies; and verifies lazy ignored fields and original evaluation order. It also exercises held group projections offline. Native request helpers and real `req_perform_sequential` are unchanged, and no HTTP execution mock replaces them.

Final results are in `verification.json`, `whole-client-generation.rds`, `whole-client-check.rds`, and `ownership.rds`. All **574 assertions** passed, with no failures, warnings or skips: 231 chemical-resolution assertions, 64 remaining-facade assertions and 279 static-media assertions. Legacy generated tests are current, with 16 remaining legacy suites. Whole-client generation requested `validation = TRUE`, and operation, mapping, retained diagnostics and signature drift are all zero. A fresh wrapper/test check reports **550 unchanged outputs**, with no writes, removals or protected outputs. All **551 owned files** match their hashes. The five held wrapper files, three canonical schemas, NAMESPACE, shared callbacks, request helpers, root pin and progress files are unchanged.

Validation reports 26 passed sources and the existing invalid archived `chemi-amos-prod.json`; that finding remains visible and is not bypassed. The default plan including every Rd file also exposed 25 inherited protected documentation differences at the base. This wave regenerates and owns only its safety Rd file, and uses the maintenance generator's wrapper/test artifact set for the fresh whole-client check. Unrelated Rd output was not promoted.

The isolated endpoint count is **309/548**, a **+1** change from the 308/548 base. This does not include the parent's uncommitted waves and does not update the shared ledger. Five scoped public wrappers remain held. The root pin is intentionally still 0.1.40; verification explicitly loads the official 0.1.41 library. The pin update and broad package check remain the parent's responsibility. No ComptoxR push.
