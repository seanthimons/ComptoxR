# Resume the full Specmill API migration

Updated 18 October 2026. Implementation checkpoint: `3829b114` on
`feat/specmill-migration-pilot`, in `/home/sxthi/Documents/Projects/ComptoxR`.

## Start here

1. Read the repository [AGENTS.md](../../AGENTS.md), then inspect branch, HEAD
   and working-tree status. At this checkpoint only the unrelated untracked
   `.planning/quick/260928-specmill-mirror-selection/` remains. Preserve it and
   leave it unstaged.
2. Continue the user's authorized full API migration. ComptoxR stays local-only:
   local commits are authorized; pushing, merging or releasing ComptoxR is not.
   Resume with offline fixtures and localhost HTTP, without production calls or
   write/upload probes.
3. Start the next individual file-contract review with the two MOL wrappers and
   AMOS PDF below. Existing native generation does not prove behavior parity.
   Then work through retained facades and remaining vector/list failure reviews.
4. For each adopted operation, finish its config, client projections, callers,
   tests/fixtures, documentation and ownership/freshness checks before committing.
   Preserve frozen legacy behavior unless a difference is explicitly reviewed.

The root handoff's September completion and delegation sections concern an older
package/database migration. Keep that work closed. No migration job or delegated
review is left running by this handoff.

## Current pin and latest adoption

The development-only [lock](../specmill-lock.json) pins Specmill v0.1.38:

- Source/tag: `f0adbc08f35142cd2f85b1a1b60606b58e9d749e`.
- Git source archive SHA256:
  `d79169d631d528ed2754fee19002f84667a84416097dfcba55b64f5e688f0373`.
- Official release archive SHA256:
  `ba38500be990f8a478f14e8a7809ca0afb08459ed7ffbbca7efd10cdc0670403`.
- Isolated library: `dev/specmill-pilot/artifacts/toolkit-library`.
  Installation/provenance workflow: [install_specmill.R](../install_specmill.R).
  Specmill is not a runtime dependency.

Commit `3829b114` adopts the reviewed five-wrapper candidate after independent
release verification and regeneration:

- `chemi_amos_get_info_by_id` and `chemi_alerts_groups_by_id`.
- `ct_chemical_file_image_search`, `_by_dtxcid`, and `_by_gsid`.

Operation `result_formatter` now runs their client purrr projections after
transport/combination, outside hook wrapping and batch drop. The two selected
list `post_combine` hooks and three obsolete list-policy functions were removed.
Image return docs describe an unnamed list for multiple inputs. The shared
request helper, compatibility executor and public signatures/defaults are
unchanged. Issue154/PR155 is released and adopted; these five are no longer held.

Released-pin verification passed 320 localhost list cases, 180 image cases,
five typed formatter catches, ten simulated native hard-401 cases and 1,332
regular assertions with zero failures/warnings. Validated whole-client freshness,
helper provenance and legacy test inventory passed. The documentation check
matches the baseline, including its existing `pipe.Rd` `%>%` note.

No full ComptoxR package check or production calls were made for this adoption.
Native 401 remains hard. Old multi-request 401 parity is deliberately excluded;
the 401 evidence is simulated, not a production endpoint failure inventory.

## Remaining work, in useful order

### File and media contracts

Review the already-native `ct_chemical_file_mol_search` and
`ct_chemical_file_mol_search_by_dtxcid` against frozen originals. Routes are GET
`/chemical/file/mol/search/by-dtxsid/{dtxsid}` and
`/chemical/file/mol/search/by-dtxcid/{dtxcid}`. The old default Accept was JSON;
native automatic media handling accepts plain text. This remains a reviewed
contract gap, not an adopted correction. Verify Accept, decoding/raw bytes,
single/multiple returns, missing positions, warnings and final conditions.

Review `chemi_amos_get_pdf(record_type, internal_id)`, GET
`/api/amos/get_pdf/{record_type}/{internal_id}`. A previous one-argument file
harness skipped this wrapper; supply both original arguments. PDF must retain
raw-byte behavior. AMOS `substances_for_ids` is Excel/binary, not proven JSON.

### Retained facades and uncertain service contracts

- `chemi_search` in `apis/search-pilot.yml`: composed interface, custom body,
  full hook state, post-on-skip and offset paging remain retained.
- `chemi_resolver_getsimilaritymap` in
  `apis/chemi-resolver-prod-rebuild.yml`: retain initial `chemicals = NULL` in
  pre-hook params, partial updates, flat resolved chemicals, skip-before-post,
  optional section omission, lowercase sort, and post-hook params excluding
  chemicals. Existing bindings have not established both exact hook states.
- `chemi_safety_rqcodes` in `apis/chemi-safety-prod-rebuild.yml`: preserve early
  empty-query error and rqCode/compact/row-bind/splitting/unit-conversion results
  and conditions. The archived Chemical-array body contract is unproven.
- Descriptor route uncertainty was recorded under Specmill #61 and ComptoxR
  #341. AMOS batch searches returned 500 HTML during earlier captures. Revisit
  evidence before declaring a working JSON contract; preserve current wrappers.
- Continue resolver, standardizer, toxprints, report/convert, PubChem, related/
  similar, hazard, alerts, AMOS batch/document and remaining CHET contracts.
  Reviewed JSON toxprint adoption does not assert upload support.

The user authorized confirmed upstream blocker implementation and releases.
Coordinate with the existing upstream agent; old explanatory config text about
separate authorization does not itself revoke that authorization.

### Already-native behavior review

The 144-query normalization adoption is complete, but does not prove every
wrapper's full failure behavior. Check each relevant vector/list operation for
effective chunk sizing/session limits, one versus many requests, transport and
received HTTP failures, warning text/order, all/partial failures, empty container
types, missing positions, attributes and malformed-success condition timing.

The legacy generated-test inventory currently reports 34 wrappers. This is a
test-inventory dimension, not a total remaining endpoint count or completion
percentage. Retained composed facades and native behavior audits are additional
work. Recompute the actual names read-only:

```r
source("dev/generate_tests.R")
e <- new.env(parent = globalenv())
source_test_generation_pipeline(".", e)
m <- e$tg_collect_wrapper_metadata(".")
b <- e$tg_validate_bespoke_contracts(m, ".")
stopifnot(b$valid)
setdiff(names(m), names(b$suites))
```

Also inspect operation `implementation`, `helper` and `specialization` settings
in `apis/`. The historical inventory JSON is a dated snapshot.
`dev/specmill-rebuild/inventory.R` writes inventory/removal files; it is not a
read-only discovery command.

### Final acceptance

After operation work, reconcile current ownership and bespoke coverage, finish
docs/signatures/examples, run clean generation and installed-package checks,
then the appropriate full suite and R CMD check. Remove compatibility helpers
only after their last callers are migrated. Eleven individually reviewed
already-missing ownership entries were retired in `beffc072` through released
public Specmill API; no blanket ownership cleanup is pending or authorized.

## Evidence to consult on demand

- [REPORT.md](REPORT.md): append-only execution history. Its final v0.1.38 section
  supersedes older holds for the five wrappers. Earlier completion claims have
  narrower scopes; read their stated exclusions.
- `pending-file-list-projections.rds/json`: initial held candidate, exact-PR155
  proof under `issue154_validation`, and released adoption under
  `release38_adoption`. Includes configs, pure functions, corrected tests/scripts,
  captured HTTP cases and logs. Top-level old verification describes the v37
  baseline; use the released block for current status.
- `failure-policy-review.json`, `pending-request-count-policy.rds` and
  `pending-exact-search-lines.rds`: corrected batch/line evidence and the
  `released_file_list_adoption` cross-reference.
- `pending-resolver-lookup.rds`, `pending-amos-keyset.rds`,
  `pending-page-pagers.rds`: frozen originals, projections and pager/lookup proof.
- `reviewed-test-retirements.json`: explicit eleven-path ownership retirement.
- Current regular suites include `test-native_collection_responses.R`,
  `test-native_failure_empty.R`, `test-native_normalization.R`,
  `test-native_additional_gets.R` and `test-native_pagers.R`.

Recent checkpoints: `1d38955b` independent PR155 proof; `beffc072` v37 ownership;
`f7962644` v36 fourteen-pager adoption; `9ade2e9e` v35 resolver lookup. All queued
generator fixes through PR155 are released. Contract uncertainty remains separate.

Temporary local material may still exist at `/tmp/complete-migration/`, including
`release38-official/`, `file37-sources.rds` and earlier repros. Inspect availability
first; committed RDS records are the portable evidence. Do not require a temporary
worktree to resume, or copy unreviewed changes from the upstream agent's checkout.

## Verification workflow and pitfalls

Use a frozen legacy definition from the relevant evidence record or its named
baseline commit. Do not use the current native wrapper as its own original.
Start a candidate in isolation and compare actual captured requests plus results,
attributes, warnings, error classes/index/parents and request completion timing.

- Keep httr2's real `req_perform_sequential`. An earlier `lapply(reqs)` mock kept
  numeric names, while the real executor returns unnamed responses. Those old
  naming claims were superseded; compare full attributes without excluding names.
- Mock transport failures as `httr2_error` with `resp = NULL`; ordinary errors do
  not exercise the real executor's continuation path. Mock received HTTP failures
  with the response and policy behavior, or use localhost.
- Final parse/format errors must run after all transport and preserve typed
  conditions. Use supported `result_formatter` and original client purrr
  projections. A normal `post_combine` hook wraps errors; per-response parsing
  can abort too early. Avoid tests that count both calls merely throwing as parity.
- Compare images using attributes/info/pixels and raw fallback bytes. External
  pointers and PNG re-encoding timestamps are unsuitable identity checks.
- `request.arguments` replaces the entire helper call. Supply complete reviewed
  bindings or use the narrower supported policy seam.
- Preserve YAML sequences when rewriting configs and use precision 17 for
  numeric values. Scope edits to reviewed operations; retain archived schemas.
- Trim deparsed R with `[[:blank:]]+$` and compare parsed expressions afterward.
  A double-escaped tab pattern previously clipped trailing letters from code;
  that mistake was corrected before the released adoption tests.
- Test cleanup/default/promise order. Lookup's deferred `tidy` value is a thunk
  called by the formatter; line callbacks see logical entries separately from
  LF wire encoding. Keep pager GET cursor NULL and POST empty-string defaults.
- Formatter/hook configuration must resolve client functions in the intended
  environment. Preserve original hook state and skip ordering rather than adding
  artificial hook calls to satisfy tests.

Useful commands, from the project root:

```sh
Rscript dev/install_specmill.R
Rscript dev/generate_tests.R --check
Rscript dev/generate_specmill.R --check
Rscript -e 'devtools::test(".", filter="native_collection_responses|native_failure_empty|native_normalization|native_additional_gets", stop_on_failure=TRUE)'
git diff --check
```

Installation needs the pinned commit in the source repo, default `../specmill`;
inspect first and use `SPECMILL_SOURCE_REPO` if appropriate. Verify provenance in
a fresh R process. To regenerate reviewed changes, use
`generate_specmill("apply")` from `dev/generate_specmill.R`. For validated full
generation, use `specmill::generate_client` with `validation = TRUE`, callbacks
from `dev/specmill_callbacks.R`, and artifacts `c("wrappers", "tests")`; require
zero diagnostics/mapping diagnostics/drift and current outputs on check.

Development loading/documentation can refresh ignored hook metadata and make
ownership hashes stale. Inspect the plan, use normal generation to refresh it,
then check again. The existing `dev/specmill-342/emit.R` and adoption record own
the approved helper provenance workflow; preserve it and never add a local
runtime patch to bypass a generator gap. Broad roxygen regeneration exposes older
stale pages; keep each operation's doc changes scoped and preserve user edits.

## Upstream coordination

Follow [AGENTS.md](../../AGENTS.md) for every confirmed unsupported seam. File an
issue promptly, or comment on the existing open fix PR, with wrapper, method,
path, schema, version, old/new behavior and a minimal reproduction. Keep affected
operations retained until the fix is released, the pin updated, and actual-client
verification passes. Supported pure client projections/normalizers/policies are
allowed; handwritten API wrappers or helper/executor patches are not substitutes.

Report confirmed blockers to the existing
[Specmill overwatch thread](t3-thread://v1/cbc44732-4d1d-4d9a-800f-80147bee5a81)
using the available thread-send capability. Include issue/PR URL, minimal repro,
expected/actual behavior and pinned version. This agent owns upstream fixes and
releases; avoid duplicate upstream implementation or a new top-level thread.

ComptoxR [PR345](https://github.com/seanthimons/ComptoxR/pull/345) is the migration
PR. Latest adoption evidence is in its
[comment](https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6247244563)
and the [PR155 comment](https://github.com/seanthimons/specmill/pull/155#issuecomment-6247244440).
Register any PR actually worked on with the available PR-linking tool. Continue
local implementation and report concrete new blockers; full migration is not
complete and there is no pending Specmill release to wait for at this checkpoint.
