# Migration status — 23 September 2026

**The expansion succeeded. Ten more functions now use specmill generation, and
their tested behavior matches the original installed ComptoxR package. The full
package migration is still unfinished.**

The branch is `feat/specmill-migration-pilot`; it has not been merged. Specmill
remains a development tool. Users of the installed ComptoxR package do not need it.

## What changed

Before this expansion, specmill generated two wrappers and maintained tests for
four retained operations. It now generates twelve wrappers and maintains tests
for the same four retained operations: sixteen operations in total.

The ten additions are:

- Alerts: `chemi_alerts_alerts()` and `chemi_alerts_operations()`.
- AMOS: `chemi_amos_release_notes()`, `chemi_amos_get_data_source_info()`,
  `chemi_amos_get_ir_spectrum()`, `chemi_amos_get_nmr_spectrum()`,
  `chemi_amos_get_mass_spectrum()`, `chemi_amos_get_info_by_id()`,
  `chemi_amos_get_classification_for_dtxsid()` and `chemi_amos_by_text()`.

Their generated code still calls ComptoxR's existing request helper. Public
names, argument order and defaults, documentation, lifecycle badges, hooks,
authentication and runtime helpers are preserved. Ten legacy generated tests
were replaced with fixed contract tests. No source schemas were edited.

## What passed

| Check | Result |
| --- | --- |
| Installed original versus migrated client | 53 localhost cases passed across all sixteen operations |
| Exact received requests | Matching methods, paths, query encoding, content types, body bytes and authentication |
| Results and failures | Matching returned objects, classes, warnings and errors; invalid inputs and hook exceptions make no fallback requests |
| Public interface | All 409 exported names and function signatures match |
| Focused tests | 234 passed; no failures, warnings or skips |
| Generation | Fresh; second generation byte-identical across 1,260 checked files |
| Ownership safeguards | Stale adoption hashes rejected; protected files retained; inseparable conflicts stop generation |
| Legacy generated tests | Remaining 321 files current |
| Package build and limited offline check | Before and after both `Status: OK`, with identical findings |

The package check disables examples, tests, vignette rebuilding and the manual.
Focused tests and localhost comparisons ran separately. This is not a full
release check. Local responses are synthetic: **live API compatibility has not
been verified**, and no production requests were made.

Hook configuration validation also passed. The legacy public-boundary check
passed with warnings about a binary file scanned as text and unrecognized
pagination patterns; those warnings are not counted as clean test results.

The previously recorded `chemi_search(all_pages = TRUE)` post-processing problem
is preserved: the tested two-page response produces an empty tibble and warning
in both clients. Matching the old result does not make that behavior correct.

## What needs upstream attention

The audit covers all 27 current production schema files: 548 declared operations.
Specmill can parse 495 individually. This does not mean all 495 have been migrated
or tested against a live service.

| Finding | What it means | Next action |
| --- | --- | --- |
| 25 invalid examples | 24 array bodies are represented as strings containing JSON; one GSID example is numeric despite a string declaration | Correct the examples after reviewing the declared contract |
| 53 blocked or unsupported routes | Missing/ambiguous media, invalid types or path declarations, unclear file representation, nested query contracts, or unsupported GET bodies | Resolve #26, #27, #28 and #31 upstream; #29 remains unsupported |
| CHET operation-name collision | Two OPTIONS routes reuse an operation ID, blocking whole-service parsing | Assign unique operation IDs upstream |
| Two additional minimal-input failures | Required multipart bodies become empty when all optional fields are omitted | Review whether a field should be required; these are fixture limitations, not invalid default examples |

For example, `/chemical/detail/search/by-dtxsid/` declares an array body but
provides a quoted string containing an array. The GSID image lookup provides
`20182` where its schema declares a string. AMOS
`/api/amos/get_similar_structures/{identifier_type}/{identifier}` declares a
path parameter named `dtxsid` that does not match either placeholder.

The [upstream issue list](UPSTREAM-ISSUES.md) gives every affected route, exact
source pointer, offending value and suggested review action. Four older CTX
snapshots are counted separately so their repeated failures do not inflate the
current-production count. Missing origin metadata is also reported separately.

Default fixtures and minimal fixtures were both tested without substituting
examples. For current schemas, defaults pass for 470 routes and fail for 25;
minimal inputs pass for 468 and fail for 27. Explicit client fixtures used in
the compatibility tests are separate evidence. Blocked routes stay out of the
generation selection; supported independent routes continue to generate.

## Reproduce and inspect

The exact toolkit pin remains
`f41eeb9bae628eeb1f0fee16227f5ee8373a7ae2`, with source archive SHA-256
`b2d3eecdb82d7dfd4fc1944197f4f4df904a0b032afb1756951cf7b2c7c8299d`.
The installer verifies the isolated loaded namespace path and source revision;
the reported package version `0.1.4` alone is not used as proof.

Run from the ComptoxR repository with Air 0.11.0 available:

```bash
Rscript dev/install_specmill.R
Rscript dev/generate_specmill.R --check
Rscript dev/specmill-pilot/audit-all-schemas.R
mkdir -p dev/specmill-pilot/artifacts/before-source
mkdir -p dev/specmill-pilot/artifacts/before-library
mkdir -p dev/specmill-pilot/artifacts/after-library
git archive 4fd720b97fb2f7f2abf131925e9270b0c11b057a | tar -x -C dev/specmill-pilot/artifacts/before-source
R CMD INSTALL --library=dev/specmill-pilot/artifacts/before-library dev/specmill-pilot/artifacts/before-source
R CMD INSTALL --library=dev/specmill-pilot/artifacts/after-library .
Rscript dev/specmill-pilot/verify-runtime.R dev/specmill-pilot/artifacts/before-library dev/specmill-pilot/artifacts/after-library dev/specmill-pilot/artifacts/runtime
Rscript dev/specmill-pilot/verify-generation.R
Rscript dev/specmill-pilot/check-package.R .
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(contract-.*|generic_request_edge|hooks_stage_server|chemi_search|ct_chemical_list_all_hooks)$", stop_on_failure=TRUE)'
```

Results are committed in `runtime-results.json`, `generation-results.json`,
`check-results.json` and `all-schema-diagnostics.json`. The original
[pilot report](REPORT.md) includes the isolated legacy-toolkit setup and its
freshness commands. All before/after comparisons use the original package at
`4fd720b97fb2f7f2abf131925e9270b0c11b057a`; the first pilot ended at `62cb6b77`.

## Rollback and remaining work

To undo only this expansion, revert its diagnostics/report commit followed by
its ten-lookup migration commit, identified with
`git log --oneline 62cb6b77..HEAD`. Revert whole commits so mappings, wrappers,
tests and ownership hashes move together. To undo the entire pilot, then revert
`62cb6b77` and `0cba7cda` in that order. Preserve any subsequent local work before
reverting. Do not reset the branch or modify the sibling specmill working tree.

Remaining work is to migrate further reviewed slices, replace remaining legacy
maintenance commands, resolve the upstream contracts and examples, investigate
the existing pagination problem separately, and run a full release check.
OAuth feature work under #4 remains outside this pilot.
