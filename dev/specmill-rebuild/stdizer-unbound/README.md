# Unbound standardizer bindings for PR345

Baseline `0935bb80`. Official Specmill v0.1.41, source
`05862bee1804806cea157ff1962300d741516301`, git archive SHA256
`70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`.
The canonical `schema/chemi-stdizer-prod.json` remains verbatim, SHA256
`178680219fccf31ecd6778532e69deff196e3767e3f8b6b3558d1cc3256f12ec`.

The source has 33 operations: eight existing native bindings, three explicitly
excluded legacy holds, and 22 candidates examined here. Six candidates remain
held by released-generator/source gaps. The other 16 receive generated native
wrappers, exports, generated Rd documentation and registered real localhost
wire/error tests. No existing native endpoint or legacy facade is replaced.
`chemi_stdizer_records_post_native(body)` exposes the declared records JSON
calculation independently of the unchanged `chemi_stdizer_records` facade.

## Migrated operations

Names and source operations are recorded together in
[the service config](../../../apis/chemi-stdizer-unbound.yml).
All paths below start with `/api/stdizer`.

- DELETE `/groups/{id}`
- PUT `/groups/{id}`
- PUT `/groups/{id}/acl`
- POST `/protocol/export`
- GET `/protocols`
- POST `/protocols`
- GET `/protocols/check`
- DELETE `/protocols/{id}`
- PATCH `/protocols/{id}`
- PUT `/protocols/{id}`
- PUT `/protocols/{id}/acl`
- GET `/protocols/{id}/changes`
- POST `/protocols/{id}/export`
- GET `/protocols/{id}/issues`
- POST `/records`
- GET `/render`

## Held operations

Newly assessed holds, with the same `/api/stdizer` prefix:

- POST `/groups/preflight`, POST `/groups/{id}/add`, POST
  `/groups/{id}/replace`: required binary query arrays; add also has a nested
  query request. [Existing #28 comment](https://github.com/seanthimons/specmill/issues/28#issuecomment-6253987290).
- GET and POST `/protocols/{id}`: required nested query object `pageable`.
  [Existing #31 comment](https://github.com/seanthimons/specmill/issues/31#issuecomment-6253987684).
  GET additionally exposes the boolean-query problem.
- PATCH `/groups/{id}/freeze`: localhost receives uppercase boolean query
  values. [Existing #177 comment](https://github.com/seanthimons/specmill/issues/177#issuecomment-6254051373).

The three user-excluded holds remain unchanged: GET
`/groups/{id}/recursive` under #166, POST `/groups` under #28/#31, and POST
`/api/stdizer` under #28/#31. The reviewed legacy proofs remain available at
`c7fd7c80:dev/specmill-rebuild/remaining-facades/REPORT.md` and its adjacent
artifacts. This change adopts no unreleased generator fix and invents no upload
contract. Every upstream comment links PR345.

## Evidence and reproduction

Run from the repository root:

```sh
bash dev/specmill-rebuild/stdizer-unbound/verify.sh
```

The script uses a persistent TMPDIR under `/home/sxthi/.cache`. Install the
pinned toolkit first with `dev/install_specmill.R` if its isolated library is
absent. No deployed mutation, upload, session operation or GET mutation is
executed. Source evidence is the canonical document and its validated operation
inventory, not a claim of deployed behavioral verification.

- `candidate-22.yml`, `discovery.rds` and `inventory.json` retain every candidate
  and exact canonical-source blocker. `verify-candidate.R` reproduces the five
  diagnostic rejections with full validation enabled.
- `held-freeze.yml`, `verify-held.R` and `held-freeze-proof.json` reproduce the
  sixth hold using real localhost HTTP and the released generated wrapper.
- `generate.R`, `generation.rds` and `ownership.json` record validated generation,
  independent freshness and every isolated output hash, including generated docs.
  The isolated NAMESPACE contains these exports and the standard auth exports; its exact generated
  bytes are preserved in `isolated-NAMESPACE.txt`. Root NAMESPACE retains all
  existing lines and appends the 16 exports. Its exports are checked by the suite.
- `verify-full.R`, `whole-client.rds` and `whole-client-proof.json` validate the
  whole client with `validation = TRUE`, wrappers/tests artifacts, fresh output,
  zero operation/mapping/retained/drift diagnostics and every final ownership
  hash. The isolated ownership is joined only in a disposable full-client copy.
  Existing source validation findings remain visible. Root manifest is untouched.
- `verify.R`, `test-results.rds` and `test-proof.json` check registered suites,
  scoped output hashes, all root ownership hashes and the standardizer suites.
  The new suite checks actual methods, routes, queries, JSON bodies, headers,
  nested validation, error statuses 400/401/404/500, malformed JSON, empty 204
  responses, and text/SVG/PNG decoding without replacing HTTP execution.
- `cases.json` and `build-fixture.R` reproduce the small wire fixtures.
  `verify-preserved.py` and `preserved.json` compare 451 existing wrappers,
  canonical sources and parent-owned artifacts byte for byte with the baseline.
- `initial-localhost-failure.log.gz` preserves the first fixture failure. Its
  HTTP 204 response left a malformed reusable connection. The fixture now sends
  an empty 204 response and closes connections. Runtime transport is unchanged.

The root pin, helpers, manifest, progress ledger and HANDOFF are unchanged.
These bindings are not added to the parent-owned ledger. There are now native
bindings for 24 of the 33 standardizer operations; the retained records facade
means that operation still fails the ledger's legacy-caller exclusion rule.
The scoped replay passed 520 assertions across ten tests with zero failures,
errors, warnings or skips. All 37 isolated ownership records match their outputs
and all 590 existing root records still match. The legacy generated-test
inventory passes with 16 retained wrappers. The first whole-client copy omitted
the package data needed during documentation loading; `initial-full-copy-failure.log.gz`
retains that failure, and the reproduction now copies package data. An additional full-copy hash failure
is retained in `initial-full-input-failure.log.gz`. The isolated setup omitted
`air.toml` and the global auth declaration, causing formatting and empty-auth
mapping differences. Generation now inherits the root project settings and
copies `air.toml`; existing root output bytes remain protected. A subsequent check found only
that the seeded cache manifest needed reconciliation, retained in
`initial-full-manifest-failure.log.gz`. The full gate now lets Specmill apply
its own manifest officially in the isolated copy before the independent check.
No whole-package test/check or live-service success is claimed by this wave.
No ComptoxR push.

Final whole-client result: **606 unchanged planned outputs**, **624 matching
ownership hashes**, and zero operation, mapping, retained-output or signature
drift diagnostics. Validation was requested with `TRUE`: 27 source reports pass
and the existing canonical AMOS invalid-source report remains visible; its
reviewed selected source passes. The four existing Mordred/WebTEST hook-route
warnings remain visible in `generation-freshness.txt`. This wave introduces no
validation bypass. `tests.txt`, `legacy-tests.txt` and `ownership-check.txt`
retain the final gate output, with trailing log whitespace removed.

## Root integration scope

Root adopts fifteen operations with official v0.1.42. POST `/records` and the proposed `chemi_stdizer_records_post_native` alias are excluded: an extra raw alias would not migrate the existing facade. The original `chemi_stdizer_records` remains assigned to the released-facade integration task. The selected config, cases, fixture and registered test name list contain only the fifteen adopted operations. Earlier isolated sixteen-operation results above are historical candidate evidence, not root coverage.
