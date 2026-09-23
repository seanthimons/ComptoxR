# Verified specmill migration pilot

This is the historical report for the initial six-operation pilot. See
[current migration status](MIGRATION-STATUS.md) for the expanded migration and
[upstream findings](UPSTREAM-ISSUES.md) for the complete schema audit.

Branch: `feat/specmill-migration-pilot`. Baseline:
`4fd720b97fb2f7f2abf131925e9270b0c11b057a`, the existing local `origin/main`
snapshot. Local `main` was clean but 68 commits behind this snapshot. It and
`integration` were left unchanged. This baseline includes the prior wrapmaint
migration and production-only API policy. No specmill configuration or manifest
existed there, despite the upstream vignette describing a later integration.
Implementation commit: `0cba7cda`. Verification scripts and this report are a
separate follow-up commit on the same branch.

The specmill working tree was already dirty. Installation uses `git archive`,
not that working tree, and no specmill files were edited. No branch was merged
or pushed and no production operation was called.

## Pin and development boundary

- Source revision: `f41eeb9bae628eeb1f0fee16227f5ee8373a7ae2`.
- Source archive SHA-256: `b2d3eecdb82d7dfd4fc1944197f4f4df904a0b032afb1756951cf7b2c7c8299d`.
- Installed namespace: `dev/specmill-pilot/artifacts/toolkit-library/specmill`
  under this checkout. The installer checks its absolute loaded namespace path,
  source commit and archive hash. The reported version, `0.1.4`, is insufficient.
- The archive is verified before extraction. Installation stamps its provenance
  into DESCRIPTION. Verification rejects a different loaded namespace or pin.
- Pilot formatting pins the locally available Air `0.11.0`. Legacy Air guidance
  and `air.toml` remain unchanged. Generation checks the exact pilot formatter.
- DESCRIPTION, NAMESPACE and all installed help files are unchanged. Neither
  specmill nor wrapmaint is a runtime dependency.

The original wrapmaint lock and installer remain available for the unconverted
operations. Its historical commit is present in the local specmill Git history,
so legacy checks were also run without downloading a release.

## Operation comparison

Identity is the original schema filename plus HTTP method and path, independent
of wrapper naming. [runtime-results.json](runtime-results.json) groups installed
before/after cases by these keys. [schema-results.json](schema-results.json)
records native parsing and fixture construction separately.

| Schema | Method/path | Public function | Pilot ownership and verified behavior |
| --- | --- | --- | --- |
| `epi-suite-prod.json` | `GET /api/search` | `epi_search` | Generated; query/default encoding, unauthenticated requests, tibble post-processing and post-hook exceptions |
| `chemi-alerts-prod.json` | `GET /api/alerts/groups/{id}` | `chemi_alerts_groups_by_id` | Generated; escaped identifier path, unchanged list return and missing-input error |
| `ctx-chemical-prod.json` | `GET /chemical/detail/search/by-dtxsid/{dtxsid}` | `ct_chemical_detail_search` | Retained stable grouped source; authentication, projection, response shaping and invalid-input rejection |
| `ctx-chemical-prod.json` | `POST /chemical/detail/search/by-dtxsid/` | `ct_chemical_detail_search_bulk` | Retained stable grouped source; exact JSON arrays, deduplication, two batches under `batch_limit=2`, aggregation |
| `ctx-chemical-prod.json` | `GET /chemical/list/all` | `ct_chemical_list_all` | Retained stable source; projection transformation, list coercion, hook order, partial updates and immediate skip |
| `chemi-search-prod.json` | `POST /api/search` | `chemi_search` | Retained maturing source; custom JSON mass-search body, pagination, full hook state and post-on-skip |

Public names, argument order/defaults, exports and documented behavior are
preserved. Explicit `inputs` and request bindings retain client validation;
schema-derived validation is not imposed on established public interfaces.
A development callback preserves the literal `c(...)` choice defaults in the
retained `chemi_search` signature, which the toolkit otherwise renders with
`base::evalq()`. The exact formals are checked against the existing definition.

The two generated files retain their experimental badges and documentation
text. Existing Rd files remain client-owned. Their initial adoption used the
reviewed hashes in [adoption-hashes.json](adoption-hashes.json); normal commands
never reuse these historical hashes. `.specmill/manifest.json` now owns the two
wrappers and six fixed tests. The legacy generator refuses to overwrite these
owned paths, including an explicit EPI rebuild. Its test pipeline defers to the
fixed contracts, retiring five metadata-derived tests. The bespoke Chemi search
suite is retained.

All request helpers, authentication, hooks, schemas, data and remaining runtime
files stay byte-identical to the baseline. Of 855 compared baseline files, only
the two reviewed wrappers differ. Helper inspections are read-only.
The independently authored helpers have unknown template baselines; the pilot
does not pretend a template is their ancestor or adopt any proposed helper code.

## Evidence and limits

- Initial focused baseline: 250 assertions, zero failures, warnings or skips.
- Expanded focused suite before retiring the old generated tests: 491 assertions,
  zero failures, warnings or skips. This includes six new fixed contracts.
- Final maintenance/fixed-contract suite after the handoff: 48 assertions,
  zero failures, warnings or skips.
- Installed clients: 23 localhost cases. Received methods, escaped paths,
  query strings, content types, raw body bytes and API-key presence are asserted
  against independent expectations, then returned objects, classes, warnings,
  error classes/messages, exports and formals are compared before/after.
  All 409 exported names and function signatures match. Neither toolkit is
  loaded in either installed-client test process.
- Invalid required/empty inputs and pre-hook failures send zero requests.
  Skip behavior sends no request; post-hook failure after transport sends exactly
  one request. No new fallback or post-hook schema revalidation was introduced.
- Six fixed specmill contracts pass. Legacy freshness passes with 331 remaining
  metadata-derived tests. Legacy wrapper freshness reports 203 unchanged and
  142 protected files. Hook validation passes for 37 functions, 111 hooks and
  34 extra parameters. Production boundary validation passes.
- [generation-results.json](generation-results.json) records second-apply byte
  equality across 1,260 files, freshness, source preservation, helper inspection and negative
  ownership tests. Custom files and existing lifecycle protections remain intact.
- Both source builds and offline R CMD check gates return `Status: OK`, with
  zero errors, warnings or notes. [check-results.json](check-results.json) retains
  the complete logs and matching dependency INFO messages. These gates disable
  examples, tests, vignette rebuilding and manual generation. Focused tests and
  installed localhost tests run separately; this is not a full release check.

The old `chemi_search(all_pages = TRUE)` helper returns collected raw records,
but its post-hook expects a response envelope. The tested two-page response
therefore becomes an empty tibble with a warning in both installed clients.
The pilot preserves this quirk and does not count it as correct live pagination
semantics. The non-paginated body case returns the expected tibble.

Native fixture modes remain separate. Five of the six default fixtures pass;
the CTX bulk endpoint fails because its selected example is a scalar while the
schema declares an array. Minimal-input mode preserves that failure. A separately
labelled explicit list-of-strings override passes. These are schema construction
results, not evidence that those default examples match ComptoxR's public inputs
or that any service accepts the requests. Fixed client contract inputs are
reviewed overrides, never substituted silently for failed schema examples.

The production-schema audit retains 53 primary parser blockers: 26 missing-media,
18 binary-query, four invalid-type, two nested-query, two path mismatches and the
resolver GET-body declaration. Independent inspection also retains masked AMOS
upload defects and nested-query overlaps. Issues #26, #27, #28 and #31 remain
blocked on service-owned contracts; #29 remains unsupported. CHET's native name
collision remains a visible schema-level error. Independent supported routes
continue to parse, and only supported keys are selected for this pilot. The
pinned toolkit refuses to apply a mixed selection containing an unsupported
route. The ownership check records that diagnostic and atomic rejection, then
verifies generation with an explicit supported-only selection. The pilot keeps
blocked routes in its audit rather than passing them through custom mappings.
No API
endpoint, archived schema, serialization contract or OAuth behavior was repaired
or guessed. OAuth #4 remains outside scope.

All compatibility claims are offline or localhost claims. Production origins,
authorization, rate limits, real response shapes and live service semantics
remain unverified.

## Reproduce

From the ComptoxR repository root, with the pinned Git revision available in
`../specmill` and Air `0.11.0` on PATH:

```sh
Rscript dev/install_specmill.R
Rscript -e 'source("dev/install_specmill.R"); verify_specmill()'
mkdir -p dev/specmill-pilot/artifacts/before-source
mkdir -p dev/specmill-pilot/artifacts/before-library
mkdir -p dev/specmill-pilot/artifacts/after-library
git archive 4fd720b97fb2f7f2abf131925e9270b0c11b057a | tar -x -C dev/specmill-pilot/artifacts/before-source
R CMD INSTALL --library=dev/specmill-pilot/artifacts/before-library dev/specmill-pilot/artifacts/before-source
R CMD INSTALL --library=dev/specmill-pilot/artifacts/after-library .
Rscript dev/generate_specmill.R --plan
Rscript dev/generate_specmill.R --check
Rscript dev/specmill-pilot/verify-generation.R
Rscript dev/specmill-pilot/verify-schemas.R
Rscript dev/specmill-pilot/verify-runtime.R dev/specmill-pilot/artifacts/before-library dev/specmill-pilot/artifacts/after-library dev/specmill-pilot/artifacts/runtime
Rscript dev/specmill-pilot/check-package.R .
```

Ordinary regeneration is `Rscript dev/generate_specmill.R --apply`. The command
plans first and stops on conflicts. Do not call `initialize_client()` here.
To replay first adoption in a disposable copy of the baseline with this pilot's
configuration and fixture files copied in, call
`generate_specmill("apply", adopt = jsonlite::read_json("dev/specmill-pilot/adoption-hashes.json"))`
after sourcing `dev/generate_specmill.R`. Mismatched hashes must fail.

Run `Rscript dev/specmill-pilot/contracts.R` only when reviewing a deliberate
fixed-fixture change, then regenerate and test. Default fixture audit failures
are not permission to rewrite those source examples.

For offline legacy checks, install its historical source into its own library:

```sh
mkdir -p dev/specmill-pilot/artifacts/legacy-toolkit-source
mkdir -p dev/specmill-pilot/artifacts/legacy-toolkit-library
git -C ../specmill archive aae88f99f6bd355a06d3404fd100b86620609e83 | tar -x -C dev/specmill-pilot/artifacts/legacy-toolkit-source
R CMD INSTALL --library=dev/specmill-pilot/artifacts/legacy-toolkit-library dev/specmill-pilot/artifacts/legacy-toolkit-source
export R_LIBS="$PWD/dev/specmill-pilot/artifacts/legacy-toolkit-library"
Rscript dev/generate_stubs.R --check
Rscript dev/generate_tests.R --check
Rscript dev/check_hook_config.R
Rscript dev/check_public_api.R
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(contract-.*|chemi_search|ct_chemical_list_all_hooks|generic_request_edge|hooks_compound|generate_tests_pipeline|stub_generation_call_shape|stub_generation_multischema|diff_schemas_counts)$", stop_on_failure=TRUE)'
```

## Rollback and remaining work

Keep this branch unmerged. Inspect the original package without altering this
working tree with `git worktree add --detach /tmp/comptoxr-before-pilot
4fd720b97fb2f7f2abf131925e9270b0c11b057a`. On a branch carrying this pilot, revert
its focused commits in reverse order. Restore the toolkit configuration,
generated wrappers/tests and ownership manifest together. The old wrapmaint pin
is unchanged. Isolated libraries live only under ignored artifacts and can be
removed after verification processes stop.

Remaining migration work:

- Review additional supported operations and transfer their generation policy and
  fixed tests in small slices. Preserve protected/grouped implementations.
- Review other legacy test-generation, schema-diff and coverage/report commands
  before replacing their wrapmaint integration.
- Address invalid upstream fixture examples openly, separate from public-client
  compatibility and parser support.
- Obtain the upstream contracts required by #26/#27/#28/#31; keep #29 unsupported.
- Investigate the existing Chemi pagination post-processing mismatch separately.
- Run a full release gate and authorized live read-only validation before claiming
  service compatibility. Production write validation is outside this pilot.
