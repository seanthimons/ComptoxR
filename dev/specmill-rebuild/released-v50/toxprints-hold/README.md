# Toxprints canonical chunk candidate and client-contract hold

Official Specmill0.1.50 removes generator issue181. This candidate remains private because canonical body/service/auth selection repairs existing public behavior under ComptoxR#311. Do not import it as a completed migration.

The retained wrapper has one public argument `query`. It normalizes duplicate/NA/blank inputs and chunks by `batch_limit`, fallback100, but inherits CTX server/auth and sends top-level arrays. The canonical source declares required object `ToxprintsRequest` with `chemicals: array<string>` and optional `options`/`profile`. The source is unchanged. `hold.json` records exact identities and the source hash; `issue-draft.md` is for the parent to check against existing issues and file separately if needed.

The private candidate uses the released `batch.input: query` with complete request mapping and a pure per-chunk projection validated through the original `.api_validation$body_value`. It sends `{chemicals:[...]}` to the Cheminformatics service without inherited CTX auth. It preserves the signature, input cleanup and chunk-size source. It does not claim all response-formatting behavior is fully reviewed or that the deployed service accepts the request.

Evidence:

- `generation.json/rds`, `generation-final.log`: validationTRUE application and exact freshness, all11 isolated owner hashes match. Both GET and POST are generated in the shared file. The first62 lines of the original owned GET are byte-identical. Root GET ownership metadata was untouched.
- `runtime.json`, `runtime-pass.log`, `test-localhost.R`:56 successful assertions and13 actual localhost requests. Exact canonical and retained legacy wires, chunk sizes, cleanup, typed500, partial drop, native hard401/config, invalid input and zeroHTTP schema rejection. `contract-wire.rds` has both request shapes.
- `legacy-default-dryrun.{rds,txt}`, `default-dryrun-pass.log`: actual retained wrapper's default CTX host/path, auth and array body, without a deployed request.
- `../upstream-client-chunks.log`: official installed-v50 upstream acceptance passes canonical object projection, normalized full input, dynamic limits, failures, hard errors and validated freshness.

Reproduce from the unchanged ComptoxR project root:

```sh
TMPDIR=$HOME/.cache/comptoxr-specmill-finish/tmp Rscript $HOME/.cache/comptoxr-specmill-finish/release50-verification/toxprints-candidate/generate.R
TMPDIR=$HOME/.cache/comptoxr-specmill-finish/tmp Rscript $HOME/.cache/comptoxr-specmill-finish/release50-verification/toxprints-candidate/test-localhost.R
TMPDIR=$HOME/.cache/comptoxr-specmill-finish/tmp Rscript $HOME/.cache/comptoxr-specmill-finish/release50-verification/toxprints-candidate/default-dryrun.R
```

Earlier failed setup/assertion logs remain for audit. The isolated configuration initially lacked the root authentication declaration, causing one harmless GET emission difference; using the root declaration restored exact GET bytes. The first runtime fixture omitted locally resolved policies, then a test incorrectly required typed HTTP401 alongside the intentionally hard native401 error. Both tests were corrected; no helper, executor or runtime code was patched.

No root tracked inputs or pin were edited, no production calls were made, and no push occurred. A full deployed behavior repair and a current package check were not performed.
