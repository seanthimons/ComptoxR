# Resume the full Specmill API migration

Updated 18 October 2026. Branch `feat/specmill-migration-pilot`, PR345.
Inspect HEAD and working-tree status before using this checkpoint. Local commits
are authorized; ComptoxR pushes, merges and releases remain held.

## Next steps

1. Read [AGENTS.md](../../AGENTS.md), the current [progress ledger](progress.md)
   and the latest entries in [REPORT.md](REPORT.md). The ledger counts canonical
   source operations with owned native output and registered behavior tests.
   It excludes held candidates and endpoints with literal legacy callers.
2. Complete current integration verification before counting or committing it.
   See `/tmp/specmill-finish/root-v41-integration-tests.log`,
   `root-v41-fresh-check.log`, `full-v41-tests.log` and
   `root-v41-package-check.log`. A focused pass does not establish a full-suite
   pass. Preserve the full-suite failure evidence and fix actual regressions.
3. Read completed delegated task results through T3 `task_status`; integrate
   reviewed changes, regenerate from the official released pin, then replay
   behavior tests in the root checkout. Child ownership manifests do not merge.
4. Continue unbound operations and retained facades. Use other families while
   upstream releases or service fixes are held. Post per-schema fractions as a
   PR345 comment after a verified iteration closes. Do not count private proofs.

A migration is complete only after config, pure client projections, public
signatures/exports, tests/fixtures, docs and generated ownership/freshness pass.
Use full generation with validation=TRUE. Retain wrappers whose generator gaps
are unreleased; file gaps upstream immediately, or comment on their existing PR.
The repository AGENTS.md defines this policy.

## Current release and root work

The root development lock selects official Specmill v0.1.41, source/tag
`05862bee1804806cea157ff1962300d741516301`. Git archive SHA256 is
`70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`;
official release archive SHA256 is
`66fc7630db90b3d353c74ecfd0db3c70b4c30337df18566acdb1db756396fe88`.
Use [install_specmill.R](../install_specmill.R) and its isolated toolkit library.
Specmill is a development generator, not a runtime dependency.

Released v39 supplied typed transport/status preservation and the official
standalone decoder. Released v40 supplied private_params/post_params. Released
v41 supplied combined post hooks and original raw post params. Helper emission
uses scaffold$code directly through [emit.R](../specmill-342/emit.R), retaining
export-to-noRd, whitespace, protection and provenance checks. No helper patch.
Native 401 and invalid call configuration stay hard; preserve_errors is explicit
in both operation controls and complete request mappings for legacy collectors.

Commits `21508aa9` and `341b8526` close the eight resolved-chemical/hazard
bindings and stale helper-mock tests. The committed ledger was 308/548.
Production-positive resolved bodies and staging-positive hazard/alerts evidence
are archived in `wave-resolved-chemical-evidence.rds`. Alerts group `ashby`
returned populated flags; a service-listed group ID that returned errors is a
rejected control. Production hazard/alerts still returned502. Similarity ordering
requires explicit main and standardization requires an explicit workflow for
positive probes; public defaults remain unchanged.

Current integration adds the actual held list-name facade, six descriptor GET/
POST facades, EPI /api and /api/download, forty service metadata/version GETs,
and four CheT reads. The focused root replay passed1607 assertions. CheT suite registration now explicitly checks the four public names against
its fixture; the ledger reports361/548 and the remaining legacy generated-test
inventory reports16 wrappers. Both scripts pass. Freshness and the broad suite
used persistent TMPDIR after initial ENOSPC. The package gate is0 errors,0
warnings,0 notes with tests/examples/vignettes/manual excluded. The broad safe
suite finished7781 passing assertions and one test-helper ordering error; that
file was corrected and its full150-assertion replay passed. Other failures and
warnings were zero;50 optional-data skips are recorded. The explicit final
freshness check passed with all590 outputs unchanged and matching ownership hashes.
See v41-integration/generation-freshness.txt.
Preserve the failed logs and the portable v41-integration/ report.

Portable reports/evidence:

- [List-name v41](REPORT-list-name-v41.md): original raw blanks/duplicates/NA
  reach the unchanged hook after native collection and final tidy formatting.
- `calculation-facades/`: six positive live descriptor operations, localhost
  wire/error/skip coverage, retained source/formatter defects.
- [CheT reads](chet-direct-reads/README.md): metadata/version/current-curator
  positive; temporary chemical detail still500, not a positive live claim.
- `service-info/`: all40 production responses checked for meaningful fields
  and absence of error payloads, plus522 localhost assertions.
- EPI /api positive JSON with14 paths. JAR bytes are validated on localhost;
  the production JAR was not downloaded during this wave.
- [Search/safety review](search-safety-v41/README.md): retained facade contracts,
 58 assertions, exact generator differences and read-only service controls.

## Held upstream/source work

- [#166/PR167](https://github.com/seanthimons/specmill/pull/167): CheT search
  fan-out and full-input validator. Root adoption stays held pending official
  release. `rootheldrelease/` contains corrected exact-head proof, commit
 434d362e3716203bf0f1438ef805c1cb950f8d0d. Of554 diagnostics,518 match exactly;
 36 are deliberate hard401 changes. Earlier24 name differences were a mock
  artifact from replacing real req_perform_sequential and have been retracted.
- [#171](https://github.com/seanthimons/specmill/issues/171): CheT GET download
  requires a body despite canonical OAS3.0 declaring it optional. Existing
  released capability works with a reviewed OAS3.1 subset and operation
  body_media: application/json. The selected-source/deployed CSV child passed;
  its commit is listed below and still awaits root integration. Preserve canonical bytes and record dialect
  and requiredness as semantic corrections, plus exact schema/ref closure and
  server provenance. Generic and selected-source localhost proofs and deployed CSV verification passed. No upstream policy
  implementation is needed if that proof passes.
- [#173](https://github.com/seanthimons/specmill/issues/173): chemi_search lazy
  paging/full hook state. Safety rqcodes additionally has an unresolved zero-
  input contract and unreleased formatting support in PR168. Retain both.
- [#165](https://github.com/seanthimons/specmill/issues/165): similarity-list
  declared getter/body return500. An undocumented getter returning[] is not
  positive behavior evidence. Keep original wrapper; no invented getter.
- [#61](https://github.com/seanthimons/specmill/issues/61): aggregate descriptor
  cross-schema/server ownership. Mordred and WebTEST predictions also retain
  documented deployed output defects. Preserve evidence rather than claiming
  a successful migration.
- [#170](https://github.com/seanthimons/specmill/issues/170): restoring owned
  file bytes/config can leave a stale ownership hash while generation reports
  unchanged. Leave old owned bytes until official generation writes new ones;
  independently verify every final manifest hash. Do not copy child manifests.

## Active delegated work

T3 task IDs share prefix
`node:delegated-task:command%3Amcp%3Afb31a767-badb-4dcf-b755-48dd4458834e%3Adelegate-task%3A`.
Read terminal results before starting duplicate work:

- `finish-remaining-legacy-cluster-20261018-1`: resolver flags/list and
  standardizer/alerts composed facades.
- `finish-mordred-webtest-four-20261018-1`: client-owned NULL-cell fix and
  four native calculation bindings. Parent private proof under persistent cache
  passed one row,1613 descriptor columns,385 NA cells; raw result unchanged.
- `finish-chet-curator-reaction-20261018-1`: additional unbound CheT routes,
  excluding admin/auth and the held search/download GETs.

Completed candidates awaiting the next root iteration, after the361 checkpoint:

- `96b2799f31492919070443234bd58fa92ba4103d`: reviewed CheT download GET.
  Selected deployed CSV proof passed495444 bytes,4028 chemical rows and30
  trailing empty records;18 localhost assertions, validated generation/freshness.
- `d216acd8`:24 management routes,688 localhost assertions, official v41
  generation/freshness and all ownership hashes. Freeze held#177: scalar boolean
  query values arrive uppercase. No mutation/live calls were made.
- `75bd0d8d9bc79f651e7718b67753d585b0892862`: PubChem evidence only, already
  copied into root. Cache lifecycle#174 and throttling#175 block adoption;
  wrappers remain unchanged. PR176 throttle implementation remains unreleased.

Overwatch thread `cbc44732-4d1d-4d9a-800f-80147bee5a81` receives concrete
proofs and owns Specmill fixes. User permits CTX keys and staging/dev validation.
Use read-only/calculation probes; production mutation/upload probes remain held.
Never print credentials or archive them in request evidence.

## Verification traps

- Full request.arguments replaces defaults: include preserve_errors explicitly.
- Adopt uses specmill:::output_hash, not raw file SHA. Filter nonexistent paths.
- Stable lifecycle badges can retain unowned files even with adopt. Freeze and
  hash-check reviewed old bytes before removing only those bytes for official
  emission; inspect file actions and all owner records afterward.
- Never sort NAMESPACE raw lines: multiline imports must stay intact. Append
  reviewed exports and parse the namespace.
- Keep generation inputs stable throughout a full generation/check call.
- Keep real httr2 sequential execution in parity tests; replacing it with named
  lapply invents names and false behavior differences.
- CRAN-safe full tests block external HTTP and allow localhost. Live service
  tests are separately recorded. Do not claim a full R CMD check when tests,
  examples or vignettes were excluded; report those gates separately.
