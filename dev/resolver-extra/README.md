# Resolver extra bindings

Twelve previously unexposed operations from the unchanged
`schema/chemi-resolver-prod.json` now have native generated bindings. The child
starts at `0935bb80`. Scope was checked against the current parent working tree
at `/home/sxthi/Documents/Projects/ComptoxR`, including its in-progress management
integration. `scope.json` records parent configuration and R source SHA256s,
registered operations, the selected routes and exclusions.

Generated operations:

- GET and POST `/api/resolver/export`, named `chemi_resolver_export` and
  `chemi_resolver_export_post`.
- POST `/api/resolver/export-append`, `/export-records`, `/export_classyfire`,
  `/exportpubchemlist`, and `/universalharvest_cart`, with matching resolver names
  and hyphens replaced by underscores.
- GET and POST `/api/resolver/export-section`, named
  `chemi_resolver_export_section` and `chemi_resolver_export_section_post`.
- GET `/api/resolver/getintegrityreports` and `/api/resolver/render`.
- POST `/api/resolver/ghs-list-count`, named `chemi_resolver_ghs_list_count_post`.

The existing `chemi_resolver_ghs_list_count()` is bound to **GET**, both in the
parent configuration and its generated R implementation. It keeps its file,
zero-argument signature, response formatting and attribution. The POST route is
separate and previously unexposed. No existing facade is replaced by a raw alias.
No other existing public wrapper or hook implementation changes. The original
bodyless resolver regression suite is included in the focused verification.

Four of the sixteen scoped routes remain held:

- POST `/api/resolver/casharvest` and `/api/resolver/universalharvest` declare
  binary arrays in query parameters, without a multipart request body. Their
  object query parameter cannot establish an upload contract.
  [Specmill #28](https://github.com/seanthimons/specmill/issues/28) and
  [#31](https://github.com/seanthimons/specmill/issues/31) already track this.
- POST `/api/resolver/exportsimilaritylist` and
  `/api/resolver/exportsimilaritymap` have scalar boolean query parameters.
  [Specmill #177](https://github.com/seanthimons/specmill/issues/177) is fixed only
  in unreleased [PR176](https://github.com/seanthimons/specmill/pull/176), commit
  `a656ce446fd2f4fe28184e3cad69da02e209ef26`. No local workaround is included.

The requested exclusions remain untouched: POST getpubchemlist, held for #173;
POST getsimilaritylist, held for #165; POST safety-flags, completed in `c7fd7c80`
for parent integration. No cache, throttle, fan-out, paging or validator fix is
reimplemented. No new generator gap was found, so no duplicate upstream issue
was filed. The zero-argument safety RQC contract remains deferred to
[ComptoxR #352](https://github.com/seanthimons/ComptoxR/issues/352).

## Generation and ownership

`apis/chemi-resolver-extra.yml` contains supported configuration for all twelve
operations. It is deliberately unregistered in root `specmill.yml`; the parent
owns integration. Each wrapper calls the released native `.ct_request` directly
and enables typed transport and HTTP errors. Hard 401 and call/configuration
errors remain native. No callbacks or handwritten wrappers are needed.

Generation loads released Specmill **0.1.41**, source
`05862bee1804806cea157ff1962300d741516301`, from the isolated library. It verifies
that the existing helper matches the released scaffold and that the emitted
validator matches the repository validator. It performs official plan, apply and
fresh check with `validation = TRUE` against the complete canonical OpenAPI 3.1
schema, then independently compares normalized SHA256s for **every** manifest
owner. Only generated wrappers and Rd files are copied into this checkout.
The isolated manifest stays in the cache project. No replacement bytes are
written over an old ownership record. `generation-proof.json` contains portable
source, validation and ownership results.

No schema derivative, body correction or deployment inference was needed. JSON
request bodies are the canonical declared objects. Export append is the one
explicit multipart contract: Chemical objects are repeated JSON parts and the
optional file is binary. This does not establish any harvest upload contract.

## Reproduce

Run from the repository root, with persistent TMPDIR set **before** each R
process. The scripts also accept `SPECMILL_V41_LIBRARY` for another verified
released v41 library and `RESOLVER_EXTRA_STAGE` for a small staging project.
Neither script modifies installed libraries.

```sh
mkdir -p "$HOME/.cache/comptoxr-resolver-extra/tmp"
export TMPDIR="$HOME/.cache/comptoxr-resolver-extra/tmp"
Rscript dev/resolver-extra/build-fixture.R
Rscript dev/resolver-extra/generate.R
Rscript dev/resolver-extra/verify.R
python3 dev/resolver-extra/check-preservation.py
```

`cases.json` freezes the canonical operation declarations. `build-fixture.R`
checks them against the canonical source and creates independent input samples,
without reading generated wrapper formals or request expressions. The suite
executes real httr2 requests sequentially against an actual localhost httpuv
server. It checks method/path/query, JSON content, multipart raw and `form_file`
bytes including NUL and 0xff, repeated Chemical JSON parts, media-dependent
JSON/text/SVG/binary/empty decoding, invalid-input zero HTTP, typed 400/404/500,
hard 401/config errors and typed connection failures with curl parents.
Fixture chemicals and report values are invented localhost inputs, not chemical
results or getter claims. No production/staging/dev requests, uploads, writes,
session changes or credentials were used.

Exports, Rd parsing, bespoke-test registrations, hook validation, canonical local
reference closure and copied owner hashes are checked by `verify.R`.
`preservation-proof.json` freezes every existing R source and canonical schema,
plus shared root configuration, pin, callbacks, manifest, ledger and HANDOFF
files against the child baseline. This includes the excluded facade sources.
The parent may continue evolving independently; these child preservation hashes
do not assert the parent's mutable working tree is frozen.

Related integration: [ComptoxR PR345](https://github.com/seanthimons/ComptoxR/pull/345).
The parent should register this service and regenerate with its official helper
and ownership records. No root manifest, helper, pin, ledger or HANDOFF change
belongs to this child. Full package check and deployed export behavior are
outside this child verification.

The final sequential focused run passed 489 assertions across 3 tests,
with zero failures, errors, warnings or skips. All 26 isolated ownership
hashes passed independently. All 449 existing/protected files stayed byte for
byte unchanged. `test-proof.json` records the focused results.
