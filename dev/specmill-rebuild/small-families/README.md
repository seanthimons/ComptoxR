# Residual small-family bindings on released v0.1.41

Scope starts at PR345's 361/548 checkpoint. Canonical schemas, parent pin,
helper, `specmill.yml`, global ownership manifest, progress and HANDOFF remain
unchanged. This wave supplies an integration candidate, not a parent-ledger
increment. No production/staging HTTP, uploads, sessions, writes or GET mutations
were performed. All wire evidence uses localhost.

New schema contracts, with no prior public functions or callers:

- `GET /api/predictor_models/model/file/` in
  `schema/chemi-predictor_models-prod.json` becomes
  `chemi_predictor_models_model_file(type_id, model_id)`.
- `GET /api/webtest/report` in `schema/chemi-webtest-prod.json` becomes
  `chemi_webtest_report(structure, endpoint, method = "consensus", format = "HTML")`.

Both return the unchanged official native decoder's JSON lists, text or binary
bytes according to received media, and NULL for empty bodies. No client formatter
or helper change. The WebTEST schema calls its required input `structure` despite
the summary's reference to a response ID; no source correction or guessed contract
was introduced. These contracts have controlled success evidence only, not a
positive deployed-service claim.

`apis/chemi-small-families.yml` is ready for parent integration. Each public wrapper
has an export, roxygen-generated Rd, and a registered real localhost behavior
suite in `tests/testthat/test-native_small_families.R`. That suite checks exact
paths, trailing slash, integer query serialization, escaped query values, schema
defaults, JSON/text/binary/204 responses, malformed JSON, actual received
400/404/500 response status/body, hard 401, early input validation and transport
condition identity. It does not replace the sequential executor or helper.

## Holds and exclusions

- OPERA `POST /api/opera/file`: official native multipart generation works, but
  scalar query `standardize` is sent as uppercase `FALSE`/`TRUE`. Existing
  [Specmill #177](https://github.com/seanthimons/specmill/issues/177) also applies.
  No old wrapper exists; leave the operation unbound until an official release
  fixes it and the parent updates the pin. Frozen official output with blank-roxygen trailing space removed,
  `held-opera.yml`, real multipart wire capture and an executable reproduction
  are kept here. No helper patch, callback conversion or bypass.
- Aggregate `GET /api/descriptors` and `POST /api/descriptors` remain held under
  [#61](https://github.com/seanthimons/specmill/issues/61). No duplicate issue,
  alternate server or facade was added.
- `chemi_safety_rqcodes`, `POST /api/safety/rqcodes`, remains deferred by the user under
  [ComptoxR #352](https://github.com/seanthimons/ComptoxR/issues/352).
  No signature or schema change.
- Safety's remaining `GET /api/alerts/render` is the same operation already owned
  by the completed management candidate `d216acd8`, which also owns hazard
  download and ToxPrint download/render. No second wrapper was generated.
- AMOS, standardizer, CheT, resolver, search/services, management and the four
  Mordred/WebTEST prediction facades belong to other tasks. WebTEST export and
  export-append are management operations. `inventory.json` records the remaining
  unbound canonical operations and dispositions outside the excluded families.

## Reproduce and integrate

Use persistent temporary storage, with official toolkit provenance verified by
`dev/install_specmill.R`. If needed, install from the committed release source
using `SPECMILL_SOURCE_REPO` and that installer. Then run from the package root:

```sh
mkdir -p /home/sxthi/.cache/comptoxr-small-families/tmp
export TMPDIR=/home/sxthi/.cache/comptoxr-small-families/tmp
Rscript dev/specmill-rebuild/small-families/prepare.R
Rscript dev/specmill-rebuild/small-families/test.R
Rscript dev/specmill-rebuild/small-families/verify.R
Rscript dev/specmill-rebuild/small-families/reproduce-held-opera.R
```

`prepare.R` recreates its own cache proof tree and generates the complete parent
configuration plus this service with `validation = TRUE` and wrapper/test artifacts,
then runs the parent workflow's separate roxygen documentation generation and
a second official apply to refresh input provenance before the independent check. It never changes the parent config/manifest. `verify.R` checks full
freshness and every proof/parent ownership hash, frozen canonical/protected bytes,
old public signatures, generated-output identity and bespoke-test registration.
Initial proof setup omitted `data/`, then `air.toml`; both were corrected.
The formatter omission caused only cache-local rewrites. A launcher edit also
caused a parse error after an apply completed. Those failed logs are preserved;
final generation and freshness run from stable scripts and the complete inputs.

Parent integration must add this service to its config and regenerate officially
with validation and ownership checks. Do not copy the proof manifest. The new
wrapper bytes here are exact official outputs and docs match the roxygen proof. Parent pin,
helper, ledger and checkpoint updates belong to the parent iteration.

Upstream operation proof: [Specmill #177 comment](https://github.com/seanthimons/specmill/issues/177#issuecomment-6254035393), linked from [PR345](https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6254038220).

## Validation result

Full official v0.1.41 generation with validation TRUE passed. The initial apply
kept all 590 parent-owned outputs unchanged and wrote only the two wrappers plus
its isolated manifest. After roxygen, the second official apply changed only the
isolated manifest. Independent full freshness passed with all 592 outputs current,
all 592 proof ownership hashes and 590 parent ownership hashes matching, zero
operation/mapping/retained diagnostics and zero drift. Existing retained
Mordred/WebTEST hook-route warnings remain visible. Both selected source schemas
passed validation. All 42 frozen schema/protected-input hashes match, and all 457
original public export contracts preserve their callable signatures.

The registered localhost suites passed 204 assertions, including 103 for the new
bindings, with zero failures, warnings or skips. Generated legacy-test inventory
is current and still reports 16 wrappers. Air and the repository-configured Jarl
checks pass. `verification.json` and `test-results.json` record the checks; the
persistent raw logs are in `/home/sxthi/.cache/comptoxr-small-families/`.

No broad package suite or R CMD check was run for this endpoint-only candidate.
No live result claim. Parent integration still must register the service and
regenerate officially; global ownership and the progress ledger are unchanged.
