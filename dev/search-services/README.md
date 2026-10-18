# Search and services migration

This isolated child covers 15 operations on released Specmill **0.1.41**, source
`05862bee1804806cea157ff1962300d741516301`. It migrates **13** and leaves **2**
unbound under the existing service input-contract hold.

| Operations | Result |
| --- | --- |
| POST `/api/search/download`, `/download/properties`, `/download/search-result-as-sdf` | New native bindings |
| GET `/api/search/download/mol`, `/download/mol-by-smiles`, `/render/png`, `/render/svg` | New native bindings |
| POST `/api/services/export`, `/export_json_report` | New native bindings |
| POST `/api/services/preflight`, `/universalpreflight` | New native multipart bindings from a reviewed derivative |
| POST `/api/services/convert`, `/collated_report` | Existing names, files and formals preserved; invalid legacy payloads corrected |
| POST `/api/services/caspreflight`, `/files` | Held under Specmill #28; no raw aliases |

`scope.json` preserves the parent's 13 canonical operation records plus proposed
names. `cases.json` records the 11 selected new operations. Names and filenames
were checked against the **current parent** configuration and R sources, rather
than only this worktree's base. The canonical search/services files equal the
current parent's source bytes and were not edited.

## Reviewed upload derivative

`schema/chemi-services-reviewed-preflight.json` is self-contained. It retains the
entire canonical services schema and local reference closure. Only the two
preflight operations change. Each required query array of binary `files[]`
becomes a required multipart request body with required array field `files[]`,
using repeated parts. No components, other operations, requiredness of file
inputs, responses, security or servers change. The canonical server remains
relative `/`; the configured `.ct_server_url` resolver selects the current
`chemi_burl` origin, whose production default is `https://hcd.rtpnc.epa.gov`.
Localhost tests exercise that same resolver and canonical `/api` path prefix.

`upload-semantic-diff.json` is the exact remove/add change. `verify-contracts.py`
replays it and compares the entire result, resolves every local reference, and
checks frozen canonical and legacy owner hashes. Before adoption, set
`SEARCH_SERVICES_PARENT` to a separate parent checkout to repeat collision checks. `source-proof.json` records canonical SHA256s.
`deployed-source.json` records the production asset URL, SHA256, byte offsets and
specific caller excerpts. The AddChemicals dialog wires services preflight to
actual multipart files; the universal dialog separately wires
universalpreflight to its own multipart file sender. No upload was made to a
production or staging server.

The other two upload contracts remain unresolved. There is no route-specific
caller evidence for caspreflight. For files, the deployed caller appends
`JSON.stringify({filesInfo: ...})` as a string form field. The accepted backend
metadata part contract remains unverified; changing it to an application/json
object part or discarding validation by accepting arbitrary text is not justified.
See the [upstream evidence comment](https://github.com/seanthimons/specmill/issues/28#issuecomment-6253840593)
and the [PR345 blocker link](https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6253862902).

## Deliberate legacy corrections

The frozen original generated definitions and exact old ownership hashes are in
`legacy-before/`. Independent inspection of `generic_chemi_request()` establishes
that it normalizes its first argument as identifiers and creates
`{chemicals: [{sid: first_argument}], options: other_arguments}`. Neither original
wrapper invokes hooks or implements skip/partial-update state. No new hook or
skip behavior is introduced.

The deployed frontend posts top-level `{content, type}` for convert and top-level
`ExportCollatedReportRequest` fields for collated report. Both canonical service
schemas agree. The official generation callback embeds the resolved source body
schema and calls the pure client body projection/validator. It omits NULL fields,
keeps the no-argument error, rejects missing/empty convert content, and validates
scalar strings and logical report flags before HTTP. Legacy vector coercion and
nested options envelopes are intentionally replaced with schema validation.
A report can now use `chemicals` without a fabricated first alertRequest value.

`calculation-evidence.json` contains actual read-only evidence. The resolver
returned Bisphenol A for the repository's existing identifier DTXSID7020182.
Its returned structure was used for both probes:

- Correct convert body: HTTP 200, nonempty MOL document. Legacy envelope: HTTP 500.
- Correct collated body: HTTP 200, 29,595-byte XLSX with the chemical name inside
  the archive. Legacy envelope: HTTP 400.

These are actual service results, not localhost sentinels. The probes do not
claim independent scientific validation of the report. `probe-calculations.py`
repeats only read-only retrieval/calculations, never upload or session endpoints.

Convert returns its actual text even when the server incorrectly labels the
unquoted MOL document `application/json`. Previously the helper attempted JSON
decoding and errored. Collated report now decodes JSON/text/binary by actual
response media, allowing the deployed XLSX response. Both wrappers preserve typed
404/500 errors. HTTP 401 is deliberately a hard `specmill_call_error`, as in the
other native bindings. Invalid runtime settings reject with zero HTTP. Existing
legacy retry behavior is measured separately: the old helper retries HTTP 500
twice; native calls honor the tested zero-retry runtime setting.

## Reproduction and evidence

Run from the repository root. Set a persistent TMPDIR **before every R command**:

```bash
mkdir -p "$HOME/.cache/comptoxr-search-services/tmp"
export TMPDIR="$HOME/.cache/comptoxr-search-services/tmp"
export SPECMILL_V41_LIBRARY=/tmp/chet-specmill41-library
python3 dev/search-services/verify-contracts.py
Rscript dev/search-services/generate.R
Rscript dev/search-services/generate-legacy.R
Rscript dev/search-services/build-fixture.R
Rscript dev/search-services/verify.R
```

The default stage directories persist under `~/.cache/comptoxr-search-services`.
`SEARCH_SERVICES_STAGE` and `SERVICES_LEGACY_STAGE` can choose fresh isolated stages.
The first generation needs no client package build. The legacy generation starts
from the frozen old owned bytes and verifies their original hashes; it does not
copy desired candidates over old ownership records. Both generations use full
validation, apply, fresh check and independent hashes for every stage-owned file.
Only generated wrappers/docs and exports are adopted into this worktree. Their
stage manifests remain separate from the parent manifest.

The registered bespoke suites execute real httr2 requests against actual localhost
HTTP servers, sequentially. They assert methods, paths, query values, JSON bodies,
repeated multipart raw/form_file bytes, response media, malformed input with zero
HTTP, typed 404/500 and hard 401/config errors. Old/native comparisons preserve
attributes through `expect_identical`, inspect parent condition classes, and
separately assert the deliberate payload/decoder/401 changes. Localhost chemical
strings are transport sentinels, never scientific calculation evidence.

`generation-proof.json`, `legacy-generation-proof.json`, `source-proof.json` and
`test-proof.json` record the portable results. The parent owns the global
pin/helper/manifest/progress/HANDOFF updates and should apply its normal generation
process after integration. The unused old global mock fixture records can be
pruned during that refresh; their two test files are replaced by registered real
HTTP tests here. No package build, full package check, ComptoxR push, production
mutation, staging mutation, session action or remote upload was performed.
