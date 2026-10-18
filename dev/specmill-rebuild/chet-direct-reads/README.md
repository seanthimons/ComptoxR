# CheT direct reads candidate

Local-only wave from `2b88f70f`, using isolated, provenance-verified Specmill
0.1.40. Four newly exposed canonical GET operations, with schema contracts rather
than legacy parity:

| Operation | Export |
| --- | --- |
| `/metadata` | `chemi_chet_metadata` |
| `/version` | `chemi_chet_version` |
| `/chemicals/chemtemp/{type}/{value}` | `chemi_chet_chemicals_chemtemp` |
| `/curators/me` | `chemi_chet_curators_me` |

`apis/chemi-chet-direct-reads.yml` owns the generated wrappers. The source is the
unchanged canonical `schema/chemi-chet-prod.json`. Inputs, scalar validation,
request serialization and decoding come from Specmill. No client projection,
handwritten wrapper, helper/executor change or pin update is needed. The native
decoder returns JSON lists, text for text media, raw bytes for binary media and
NULL for an empty response. In particular, a CSV advertised as `text/csv` is text,
not an automatically parsed table.

All four exports have generated Rd documentation and registered permanent
behavior coverage in `test-native_chet_direct_reads.R`. Its JSON fixture declares
independent expected paths and inputs. Tests exercise actual localhost
GETs, segment encoding, no query/body on reads, JSON/text/binary/204 decoding,
malformed JSON, received 400/404/500 response preservation, hard401, original
transport-condition identity and early schema validation. These are new endpoint
contracts, not snapshots of any retained prototype.

## Live evidence and source limits

`live.R` reproduces credential-free read-only evidence in `live.rds`.
Metadata and version returned HTTP200 JSON on 2026-10-18. Curator-session
inspection returned HTTP200 with authenticated=false and user=null without
credentials. The held download with an empty JSON object returned HTTP200
`text/csv`, 495444 bytes. The raw probe uses a named empty list to serialize `{}`.

The download schema declares its body optional, but the deployed server returns
HTTP400 `Request body must not be empty` when it is omitted. Specmill v0.1.40
drops this OpenAPI3.0 GET body entirely and emits no body argument. This route is excluded, with upstream blocker
[specmill#171](https://github.com/seanthimons/specmill/issues/171), linked from
ComptoxR PR345. No local bypass or download wrapper is adopted. Both
`dtxsid/DTXSID7020182` and `casrn/80-05-7` temporary-detail probes returned HTTP500. The schema supplies no
identifier-type vocabulary. Temporary details therefore have offline contract
coverage only, with no successful production-result claim or guessed enum.
The temporary-detail result is a source/server limitation, while download
requires the upstream reviewed-GET-body capability. The schema snapshot was not
changed. Neither the held download nor its prototype counts as a completed
endpoint.

Admin, authentication, protected curator/editor, DB backup and error-workflow
routes were excluded because they require sessions, perform actions or lack a clear public
read contract. Existing bindings and both #166 held search facades were excluded.
No other worker's endpoints, shared progress ledger or PR checkpoint was edited.

## Reproduce

From this worktree root, with the isolated toolkit installed using
`dev/install_specmill.R` and the committed v0.1.40 lock:

```sh
Rscript -e 'source("dev/install_specmill.R"); verify_specmill(); cb <- new.env(parent=baseenv()); sys.source("dev/specmill_callbacks.R", cb); specmill::generate_client(root=".", config="specmill.yml", callbacks=cb, mode="apply", artifacts=c("wrappers","tests"), validation=TRUE)'
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(native_chet_direct_reads|native_received_http|specmill_adoption)$", stop_on_failure=TRUE)'
Rscript dev/specmill-rebuild/chet-direct-reads/verify.R
```

`verification.json` records the validated full-generation freshness result and
source ownership hashes. Root manifest changes register generated wrapper
ownership. NAMESPACE and Rd files follow the package's separate roxygen workflow. Verification builds
documentation in a temporary copy and compares these four Rd files and NAMESPACE
byte for byte, leaving unrelated documentation alone. The parent must regenerate
those shared outputs when combining this candidate with its separate v0.1.41 adoption.

The isolated installed-client probe is reproduced with:

```sh
mkdir -p dev/specmill-pilot/artifacts/chet-client-library
R CMD INSTALL --library=dev/specmill-pilot/artifacts/chet-client-library .
Rscript dev/specmill-rebuild/chet-direct-reads/installed-live.R dev/specmill-pilot/artifacts/chet-client-library
```

`installed-live.rds` records the final exported wrappers, including the preserved
received HTTP500 for temporary details.

## Validation result

The committed behavior run passed 249 assertions with no failures, skips or
warnings: 148 new direct-read assertions, 81 existing received-HTTP assertions and
20 existing decoder/pagination adoption assertions. `test-results.json` records
that run. The localhost fixture closes each response connection so changing
between binary, empty and error responses cannot reuse an earlier connection.
The final installed-client probe passed its assertions. No package-wide test or
R CMD check was run for this endpoint-only wave.
