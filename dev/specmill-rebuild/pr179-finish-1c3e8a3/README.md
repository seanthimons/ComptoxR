# PR179 independent exact-source replay, second round

Private proof only. The three previously reported generator blockers now pass
against Specmill `1c3e8a34c41eba5d2a20cc46f8bc2e39abb6d18c`, tree
`8b3d85ce4da993058d2e85703d843ad50d5c66dd`. Source archive SHA256:
`3f494caf0842915624d5ba79aa4f9d3583c7e82d3392ac77f0efcf4e05b8c1ee`.
This unreleased source still reports package version 0.1.41; the archive identifies it.

Previous proof commit `c200d75116bf5a2e0eaf254aa85e44e8d5fe1cfb` and its
`pr179-exact` evidence in the other worktree remain untouched. This directory is
a new round, based on ComptoxR `cd34efb4` with the same held facade, hook,
legacy collector and native helper bytes. Provenance records full hashes.
Only evidence in this directory is committed. No root wrapper/helper, mapping,
pin, schema, NAMESPACE or ownership adoption; no push or deployed service writes.

## Results

Final focused replay: **9 tests, 227 assertions, zero failures, errors, warnings
or skips**. The exact upstream `tests/request-pagination.R` also passes unchanged.
Both canonical schemas pass full validation, both private wrapper owner hashes
match, freshness reports unchanged, public formals match old, and official helper
code/provenance match a fresh scaffold byte for byte. Production hashes remain
unchanged. See `test-totals.json`, `tests.txt`, `verification.json`,
`generation.txt` and `upstream-request-pagination.txt`.

- Search, POST `/api/search`, `schema/chemi-search-prod.json`: `pre_params`
  excludes deferred `all_pages` from applied updates. With original TRUE and
  partial hook state containing FALSE, both old and candidate make two real
  localhost requests and return identical post state, retaining FALSE and extra
  fields. No callable overwrite occurs.
- Same operation: explicit `post_state: hook_state` plus
  `post_result_null: remove` matches old NULL-key removal. The independently
  generated default-policy variant retains named NULL. Skip paths with
  `all_pages=stop('forced')` remain lazy and run one pre/post cycle.
- PubChem, POST `/api/resolver/getpubchemlist`,
  `schema/chemi-resolver-prod.json`: both `{from: [params,max_pages]}` and
  callback caps generate and execute. Original caps 1/2 and partial hook cap
  overrides match old result counts, make the expected requests, and run one
  pre-hook. Invalid 0, negative, fractional, NA, string, NULL and infinite caps
  fail before HTTP when paging. Those values do not trigger cap validation in
  single mode or skip mode. The fixed-100 diagnostic fallback was removed.

The replay reuses original facades, actual hooks and actual `.ct_legacy_pages`,
with real localhost HTTP and native httr2 sequential execution. Only the hook
boundary is replaced in state-specific tests. Pure policy callbacks project body,
response and page metadata; there is no local pager or patched executor.
`initial-harness-failure.txt` records a harness-only failure: the separately loaded
callback variant initially lacked its result formatter in its own environment.
Sourcing the same policy file there fixed the harness; no emitted code was edited.

## Holds and limits

No further generator gap was found in this focused replay. PubChem's independent
source/service mismatch remains held: old nested ChemicalRecord/options versus
schema flat Chemical, five required query controls absent from public formals,
and service items/total versus old records/totalRecordsCount. A localhost
items/total payload still produces an empty legacy-shaped result. No new deployed
service verification is claimed, and the generator did not correct that mismatch.

Existing diagnostic wire differences remain: native paging adds first offset=0
and PubChem options.limit=100. These assertions establish the three repaired
contracts, not full wire parity or a working deployed PubChem endpoint. Native
hard401 and native dryrun remain deliberate policies separate from legacy error
recovery/debug printing. Other checks retain partial404/500, malformed JSON and
metadata, transport failure, actual normalization and resolver execution.

Official emitted wrappers and the raw initial failure log retain trailing whitespace;
`git diff --check` flags those archived bytes. They were not reformatted.

Full upstream R CMD check and the whole ComptoxR suite were not run. Adoption
remains held until upstream release/pin update and explicit PubChem source/service
review, followed by root regeneration and package gates.

## Reproduce

Run `bash dev/specmill-rebuild/pr179-finish-1c3e8a3/install.sh` from the repo root.
Every R process uses persistent TMPDIR
`/home/sxthi/.cache/comptoxr-specmill-finish/tmp`, never the full /tmp tmpfs.
The private library, extracted exact source and generated project live beside it.
The installer verifies the SHA and archive hash, uses the official scaffold and
public generator, runs validation/freshness, replays tests and verifies hashes.

Results are reported to [Specmill PR179](https://github.com/seanthimons/specmill/pull/179)
and linked from [ComptoxR PR345](https://github.com/seanthimons/ComptoxR/pull/345).
No duplicate upstream implementation or issue was created.
