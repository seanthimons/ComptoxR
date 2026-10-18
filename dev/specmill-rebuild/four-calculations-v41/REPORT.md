# Four dedicated calculations on released v41

This worktree starts at `341b8526`. It migrates `chemi_mordred`,
`chemi_mordred_bulk`, `chemi_webtest_predict`, and
`chemi_webtest_predict_bulk` to official Specmill-generated `.ct_request`
bindings. These are generator migrations. Live WebTEST predictions remain
unavailable because the deployed response lacks endpoint IDs.

The root checkout was read only. Its native descriptor mappings and development
response callbacks supplied the pattern. No pin, runtime request helper,
executor, `generic_request`, shared progress/disposition ledger, or HANDOFF was
changed. Aggregate `chemi_descriptors` / `_bulk` remains held under Specmill #61.
No ComptoxR push or upstream job was performed; no new generator gap was found.

## Client formatter correction

`format_descriptor_result()` previously assigned NULL into a list element with
`[[<-`. R deletes that element. This loses row alignment and can collapse a
returned chemical to zero rows. The shared client formatter now changes a NULL
cell to NA before assignment. It preserves the chemical and treats the returned
scientific value as missing. No hook lifecycle or public signature changes.

The regression suite covers a single NULL, multiple NULLs, multiple all-NULL
chemical rows, and mixed NULL/numeric cells. It checks row count, input order,
status, values, and raw payload preservation. The existing formatter and
prediction hook suites passed before adoption, with 225 assertions and no
failures, warnings, or skips.

`prove-null-fix.R` independently replays archived production bytes using the
original wrappers and the actual formatter with and without the new guard.
Both GET and POST change from zero rows to one row. Raw results, including
provenance attributes, are identical. `null-fix-proof.rds` records this check.

## Generated requests and tests

Mordred keeps its original `headers`, `inchi`, and bulk `options` contracts.
The GET and POST descriptor callbacks use the existing client collectors.
WebTEST prediction requests use the same JSON transport semantics and retain
`filter_webtest_prediction_result()` unchanged. Wide mode rejects malformed
endpoint records. Raw mode continues to expose the unchanged payload.

The portable native suite compares frozen original expressions with the
namespace's generated functions. It covers controlled valid predictions,
malformed payloads, raw/wide results, complete hook state, warnings, resolution,
engine options, duplicates, skips, partial parameter updates, private state,
HTTP errors, transport errors, hard 401, and invalid request controls. A real
localhost server checks GET queries, POST bodies, headers, successful controlled
responses and received HTTP errors for all four operations. Controlled prediction
data is test data, not a claim of deployed prediction success.

Only the four old fixed helper tests were retired through public
`specmill::apply_files`, after checking their exact normalized owner hashes and
registering the replacement bespoke suite. Their four fixture entries are
archived in `retired-fixed-contracts.rds`. Every other fixture key and value is
identical to the base commit. Existing hook-only suites use frozen old facades;
the new native suite checks the real generated functions.

## Production evidence

Fresh public calculation probes at `2026-10-18 18:51:17 UTC` used `CCO`, with
`LC50` requested for predictions. They required no CTX resolution or credentials.
`fresh-production.rds` retains response bytes and conditions.

- Mordred GET and POST both returned HTTP 200, one `ok` chemical row,
  1,613 descriptor columns and 385 missing values.
- WebTEST prediction GET and POST both returned HTTP 200 and then the existing
  `comptoxr_post_response_hook_error`: `PredictionResult endpoint is missing its
  endpoint id.` Live scientific predictions are still unavailable. No endpoint
  IDs were fabricated and no validation was relaxed.

Archived production GET/POST responses also pass old/native parity. These
fixtures travel with the portable tests under `tests/testthat/fixtures`.

## Validation results

The final focused run passed 606 assertions: 381 native parity/localhost checks
and 225 formatter, regression and hook checks. There were no test failures,
warnings, errors or skips. `focused-tests.rds` retains the results.

The fresh official-v41 generation check exited successfully with all 545 outputs
unchanged and zero generation diagnostics, mapping diagnostics, retained
diagnostics or signature drift. All 545 normalized owner hashes match.
`verification.rds` also records valid declarations for four functions, 22 hooks
and six extra parameters, preserved fixture keys, signatures, exports and docs.

Schema validation was enabled for the complete configuration: 26 source schemas
passed. The existing legacy AMOS Swagger source remains invalid under its
already committed reviewed-document policy. Neither that source nor its policy
changed. Twelve warnings repeat the six legacy PaDEL/RDKit/WebTEST descriptor
route warnings in this older base, twice each. These six bindings are already
native in the parent checkout and are outside this four-binding change. The
Mordred and WebTEST prediction sources pass validation and introduce no such
warnings. `generation-check.rds` retains the full validation and warning records.

## Reproduction and integration

Set a dedicated persistent temporary directory before launching R:

```sh
mkdir -p "$HOME/.cache/comptoxr-four-v41/tmp"
export TMPDIR="$HOME/.cache/comptoxr-four-v41/tmp"
export SPECMILL_LIB=/tmp/chet-specmill41-library
Rscript dev/specmill-rebuild/four-calculations-v41/generate.R
Rscript dev/specmill-rebuild/four-calculations-v41/verify.R
Rscript dev/specmill-rebuild/four-calculations-v41/prove-null-fix.R
Rscript -e 'devtools::test(filter="native_four_calculations|descriptor_contracts|descriptor_smiles_hooks|descriptor_null_cells|hooks-webtest", stop_on_failure=TRUE)'
```

`generate.R --apply` is the adoption command. `retire-tests.R` is the one-time
fixed-test retirement already applied here. `probe.R` repeats the four public
calculation probes and records whatever the deployment currently returns.

The toolkit is release `0.1.41`, source
`05862bee1804806cea157ff1962300d741516301`, archive SHA256
`70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`.
The temporary library and root isolated library have identical provenance,
recorded in `library-provenance.rds`. This worktree's baseline v40 pin is unchanged;
integration must retain the parent's released v41 pin. `release-provenance.json` is this run's
evidence record, not a replacement repository pin.

Generation uses the complete `specmill.yml` with `validation=TRUE` and the
repository's established wrapper/test artifact scope. An initial all-artifact
apply refused protected outputs without applying files. The four Rd topics
parse and are byte-for-byte unchanged from base; NAMESPACE is also unchanged.
Only this isolated checkout was staged for generation, with no root development
artifact build copy.

The parent must regenerate against its current integrated v41 configuration
when applying this commit. Its existing six native calculation bindings and
shared ledgers were intentionally not copied into this older-base worktree.

Full package R CMD check and the entire test suite were not run.
