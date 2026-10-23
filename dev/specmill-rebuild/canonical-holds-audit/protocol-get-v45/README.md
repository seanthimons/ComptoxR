# Isolated reviewed protocol GET candidate

Operation: GET `/api/stdizer/protocols/{id}`, canonical `schema/chemi-stdizer-prod.json`.
Public name: `chemi_stdizer_protocols_by_id_get(id, hidden=NULL, components=NULL, changed=NULL, failed=NULL, passed=NULL, page=NULL, size=NULL, sort=NULL)`.

Nothing in the root client/config/schema/manifest/pin was changed. This is an isolated candidate, not an adoption or endpoint-count claim.

Official Specmill 0.1.45 is loaded from the separate root versioned library. Installed DESCRIPTION source commit is `f686717052b7636775ce1ccca2080056c32f69f0`. The helper is emitted directly by official `request_helper_scaffold()` with root's existing registered settings, including companion provenance. No helper/executor/wrapper patch is used.

`schema/chemi-stdizer-reviewed-protocol-get.json` selects GET only, preserves its original five optional boolean fields and response exactly, and copies the full referenced component closure without changes. It applies the already reviewed optional flat page/size/sort correction from the POST derivative. Canonical source stays unchanged. `evidence/provenance.json` records exact before/after declarations, canonical/output hashes, source URL/retrieval provenance, reviewed semantic corrections and prior GET/POST service evidence. `derive.py` asserts the exact derived bytes and preserved declarations/ref closure.

The complete request mapping uses supported `parameter_serialization` metadata for all five boolean fields. This explicitly invokes native schema boolean encoding and emits lowercase true/false; complete mappings without this metadata retain the old generic field encoding. Production server remains explicit and `server_resolver.relative='/'` handles the existing default `chemi_burl` ending `/api` without duplicating it. `preserve_errors=true` is passed explicitly in the complete mapping. Existing pure `.ct_protocol_sort` maps character() to omission. No public wrapper collision exists in the baseline root.

Validation/freshness: `evidence/generation.json` and `.rds` record validation=TRUE generation, check freshness, zero operation/mapping/retained/drift diagnostics, and all8 output owner hashes matching. Source SHA256 is `36ff68551f9dc9ef891fe47e691473f1818f0f1114125a315abdec4e7ffd2e5d`.

Localhost suite: final `evidence/tests.json` / `.rds` / `.log` records190 passing assertions,0 failures/errors/warnings/skips. Covers all32 combinations of the five boolean flags with exact lowercase query bytes, page/size, repeated encoded sorting, each NULL flag, absent defaults, empty-string sort, NULL/character() omission, injection escaping, default production URL, base `/api`, bodyless GET, invalid input zeroHTTP, typed400/404/500 with original response bytes, hard401/config errors,204 and transport failure.

The first fixture expected query fields in schema order; native parameter metadata moves encoded boolean fields after untyped page/size. Its32 order-only failures are preserved as `evidence/initial-query-order-tests.*`. The correction changed test expectations, not generated/runtime/config/source behavior. The test's later NULL-string fallback was inlined so it has no runner-only helper dependency; the final rerun is authoritative.

Deployed read verification: `evidence/live.json` / `.log` records12 calls through the actual generated candidate, both production and staging, with `/api` bases. All IDs match the separately recorded GET page0/page1/descending/repeated-sort/empty-sort/absent controls for a protocol selected from service listing. Four meaningful baseline records; filteredNumber remains4. No deployed writes, uploads, auth/session or mutation calls.

Reproduce from ComptoxR root, with `TMPDIR=/home/sxthi/.cache/comptoxr-specmill-finish/tmp`:

```
python3 ~/.cache/comptoxr-specmill-finish/protocol-get-candidate/derive.py
Rscript ~/.cache/comptoxr-specmill-finish/protocol-get-candidate/generate.R
Rscript ~/.cache/comptoxr-specmill-finish/protocol-get-candidate/run-tests.R
Rscript ~/.cache/comptoxr-specmill-finish/protocol-get-candidate/live.R
```

For root adoption, see import-plan.json and the unexecuted parent-only import-files.R. Target config is apis/chemi-stdizer-reviewed-protocol-get.yml, source schema/chemi-stdizer-reviewed-protocol-get.json, test tests/testthat/test-native_stdizer_protocol_get.R, provenance dev/specmill-rebuild/canonical-holds-audit/protocol-get-v45/provenance.json. Public apply emits the wrapper; do not copy candidate ownership. Use exact service/schema/official Rd plus the standalone test. Restore the established service `hook_config` field/register the bespoke test, include the service in specmill.yml, add canonical progress provenance alias, generate via public apply/check, export/register docs and run root/installed gates. Existing `R/stdizer_protocol_policy.R` is reused. Root ownership and pin remain the parent's responsibility; no candidate hashes should be spliced into the root manifest.

No fresh full package check or root freshness was performed by this task. AMOS XLSX wrappers remain deferred as requested; other standardizer nested-query holds are unchanged.
