# Whole-client migration attempt

The remaining review work is tracked in [five GitHub category issues](REVIEW-ISSUES.md),
with complete function checklists, acceptance criteria, and supporting evidence.

## Maintenance continuation, 24 September 2026

The migration now has a dedicated **Specmill Maintenance** CI workflow. The
previous workflows checked only legacy generation. This job checks the existing
105-operation specmill configuration on every pull request, pushes to `main` and
`integration`, and manual dispatch. It reads the existing source pin, checks out
that revision into ignored development artifacts, and verifies the archive
checksum and installed namespace with `dev/install_specmill.R`.

The job uses Air 0.11.0 separately from the legacy jobs' Air 0.9.0. It runs the
public-address boundary check, generation freshness, fixed contracts and client
policy tests, then requires apply/check to leave no modified or new files.
The address check uses `membership = FALSE` because export membership is already
checked with the legacy toolkit in the CRAN readiness job. No API credentials are
provided. Verification stays offline or on localhost, and migration remains
limited to public API endpoints.

Local verification reinstalled and verified the pinned specmill package and
passed all 412 focused assertions with no failures, warnings or skips. Workflow
YAML, embedded R, and shell commands passed parsing checks. Generation freshness
passed, and a repeated apply preserved all tracked file hashes. The existing full
public-boundary check also passed. It emitted two pre-existing encoding warnings
while scanning a UTF-16 text file. Hosted GitHub Actions execution remains
unverified until this branch is pushed.

This continuation adds no wrapper mappings. Counts and upstream blockers below
remain unchanged. To roll it back, revert the dedicated CI continuation commit;
the earlier wrapper adoption does not need to be reverted.

## Wrapper migration results

The broad attempt succeeded for **89 additional wrappers**. Together with the
previous pilot, specmill now generates **101 wrappers** and maintains fixed
contracts for **four retained implementations**. The complete package migration
is **not finished**: the remaining wrappers need reviewed mappings or must stay
manual, and legacy maintenance commands are still in use.

The work stays on `feat/specmill-migration-pilot`, unmerged. No schemas, runtime
helpers, hook implementations, authentication policies or production endpoints
were changed. Specmill remains a development dependency.

## What the full pass found

Every one of the 409 exported names was accounted for. This was a conservative
conversion of existing public wrappers, not an attempt to add a public function
for every schema route.

| Disposition in the initial screening | Exports |
| --- | ---: |
| Additional candidates, subsequently verified and adopted | 89 |
| Already generated in the previous pilot | 12 |
| Protected or incomplete lifecycle/ownership metadata | 113 |
| Custom implementation needs a manual mapping | 93 |
| Hook policy needs a manual mapping review | 26 |
| No unique supported schema/method/path match | 16 |
| Grouped file has an inseparable retained definition | 4 |
| Outside CT/Chemi/EPI schema-wrapper scope, including two operators | 56 |
| Total | 409 |

These are mutually exclusive screening reasons, not counts of defective
functions. Four operations in the retained categories already have specmill
configuration and fixed contract tests from the original pilot. A retained
function continues to use its existing implementation.

Of the 353 public CT/Chemi/EPI wrappers, 105 are now covered by this integration.
The other 248 still need a maintenance decision or reviewed mapping. The
remaining 56 exports are outside this schema-wrapper scope.

[attempt-results.json](attempt-results.json) records the decision for each export.
The 89 candidates span AMOS, CHET, Resolver, Services, Stdizer, Toxprints,
CTX Chemical, CTX Exposure and EPI Suite. Their 81 source files were reviewed as
complete groups; no partially mapped grouped file was replaced.

## Compatibility evidence

The installed original client at
`4fd720b97fb2f7f2abf131925e9270b0c11b057a` was compared with an installed isolated
copy containing all 89 candidates. **459 localhost cases passed, with no
candidate failures.** These include the original 53 pilot cases.

The comparison checks exact received HTTP methods, paths, query encoding,
content types, body bytes and authentication; returned objects and classes;
warnings and errors; all 409 public signatures; batching and duplicate removal;
two bounded pagination requests; missing and empty inputs; and the existing
hook-order, state, skip and exception cases. Invalid inputs and hook exceptions
make no fallback requests.

All 105 fixed contract tests also passed their 210 helper-call and result
assertions in the isolated copy. The fixed expectations were captured from the
original wrappers before adoption, then compared with rendered candidates.
Transport expectations were checked separately at the localhost server.

[runtime-results.json](runtime-results.json) records stable schema/method/path
keys and individual case results. [runtime-cases.rds](runtime-cases.rds) holds the
frozen public inputs and original helper arguments. These explicit client
fixtures do not replace upstream default examples or minimal schema fixtures.

All 81 source files adopted into the working package match the tested isolated
copy byte for byte. The comparison was then repeated against an installation of
the adopted working package, again passing all 459 cases.

The adopted package also passed 412 focused assertions with no failures,
warnings or skips. Its remaining 232 legacy-generated tests passed freshness
checks; the 89 replaced tests were retired by the existing ownership-aware
test generator.

The original and migrated package builds and limited offline `R CMD check`
both returned `Status: OK`, with identical findings. The full output and check
exclusions are recorded in [check-results.json](../specmill-pilot/check-results.json).

Generation is current. A second apply was byte-identical across 1,261 checked
files. Comparison with 855 original runtime, documentation, schema and data
files found only the 93 reviewed wrapper files changed across the entire
migration. Lifecycle badges, client helpers and protected files remain intact.
Stale adoption hashes, protected contract conflicts and unsupported mixed
selections were rejected; explicitly scoped supported generation still worked.
See [generation-results.json](../specmill-pilot/generation-results.json).

## Existing behavior exposed by the wider tests

These observations are compatibility findings, not repairs:

- A lookup value containing `/` retains an encoded slash when no URL-query update
  occurs. Adding query arguments, even an omitted `NULL` argument, can leave the
  slash unescaped in the path. Both installed clients behave identically. This
  should be investigated separately in the shared request helper.
- `chemi_toxprints_chemicals_categories()` and
  `chemi_toxprints_toxprints_categories()` accept optional public arguments, but
  calling them without identifiers errors before sending a request. The tests
  keep those default-input failures separate from successful explicit inputs.
- The previously documented `chemi_search(all_pages = TRUE)` result-shaping
  problem remains unchanged. Preserving an empty result and warning does not
  certify that pagination behavior as correct.

All responses were synthetic and all requests went to localhost. No live API
behavior has been verified, and no production write calls were made.

## Upstream findings still need review

The [full schema audit](../specmill-pilot/UPSTREAM-ISSUES.md) remains applicable:
27 current production files declare 548 routes; 495 parse individually and 53
remain blocked or unsupported. Among parsed routes, 25 default examples are
invalid. Two further failures occur only with empty minimal multipart fixtures.
CHET also has a duplicate OPTIONS operation ID that prevents whole-service
parsing. The selected CHET wrappers use independent supported keys.

Issues #26, #27, #28 and #31 still require upstream contracts. #29 remains
unsupported. OAuth #4 remains outside this work. Neither examples nor contracts
were silently repaired to make this migration pass. Four older CTX snapshots
remain separate from current-production counts.

## Reproduce

The exact specmill pin is unchanged:
`f41eeb9bae628eeb1f0fee16227f5ee8373a7ae2`.
The source archive SHA-256 is
`b2d3eecdb82d7dfd4fc1944197f4f4df904a0b032afb1756951cf7b2c7c8299d`.
The isolated installer verifies both the loaded namespace path and source pin.

From the repository root, with Air 0.11.0 available:

```bash
Rscript dev/install_specmill.R
Rscript dev/generate_specmill.R --check
mkdir -p dev/specmill-pilot/artifacts/before-source
mkdir -p dev/specmill-pilot/artifacts/before-library
mkdir -p dev/specmill-pilot/artifacts/after-library
git archive 4fd720b97fb2f7f2abf131925e9270b0c11b057a | tar -x -C dev/specmill-pilot/artifacts/before-source
R CMD INSTALL --library=dev/specmill-pilot/artifacts/before-library dev/specmill-pilot/artifacts/before-source
R CMD INSTALL --library=dev/specmill-pilot/artifacts/after-library .
Rscript dev/specmill-full/verify-runtime.R dev/specmill-pilot/artifacts/before-library dev/specmill-pilot/artifacts/after-library dev/specmill-pilot/artifacts/full-runtime
Rscript dev/specmill-pilot/verify-generation.R
Rscript dev/specmill-pilot/check-package.R .
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(contract-.*|generic_request_edge|hooks_stage_server|chemi_search|ct_chemical_list_all_hooks)$", stop_on_failure=TRUE)'
R_LIBS=dev/specmill-pilot/artifacts/legacy-toolkit-library Rscript dev/generate_tests.R --check
```

The [initial pilot report](../specmill-pilot/REPORT.md) gives the isolated legacy
library setup. The package check is deliberately offline and excludes examples,
tests, vignette rebuilding and the manual; tests run separately. It is not a full
release gate.

`prepare.R` reproduces the screening against the archived original source and
writes proposals into ignored artifacts. `stage.R` was the one-time pre-adoption
review step: it refuses an existing staging directory or source files differing
from the reviewed original. Routine regeneration uses `dev/generate_specmill.R`;
do not pass old adoption hashes again. The runtime verifier exits unsuccessfully
if any candidate fails, even when both clients share that failure.

## Rollback and remaining work

This attempt starts after `697f15c9`. To undo it, identify its focused commits with
`git log --oneline 697f15c9..HEAD` and revert them newest first. Revert mappings,
wrappers, fixtures, tests and ownership manifests together. Preserve later local
work before reverting. The sibling specmill checkout is unchanged.

The implementation commit is `1444ca5f`; revert the following results/report
commit first, then that implementation commit.

The next work is manual mapping review for the retained wrappers, upstream
contract/example corrections, and replacement of the remaining legacy
maintenance commands. Protected implementations should remain manual unless
there is a specific reason to change them. Full release and authorized live
read-only checks would be separate work.
