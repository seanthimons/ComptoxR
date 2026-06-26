---
issue: 179
bean: ComptoxR-epem
parent: ComptoxR-8z9q
milestone: "Now: CRAN Release Readiness"
status: audit-complete
scope: audit-only
audit_artifact: dev/reports/unit_test_readiness_audit.json
audited: 2026-06-26
---

# Unit-Test Readiness Audit for CRAN Release

## Verdict

ComptoxR is not yet unit-test ready for CRAN release. The repository has a large test surface, but the current evidence is not yet a CRAN-safe, authoritative coverage story:

- `dev/test_manifest.json` is stale: it lists 45 generated files, but only 4 of those files exist in `tests/testthat`.
- 209 of 233 current test files contain the generated-test header, yet 58 generated tests call backticked endpoint-style names with hyphens instead of exported R functions.
- 218 test files use VCR, but no test file calls `skip_on_cran()` and no test file calls `skip_if_no_key()`.
- Literal cassette references and committed fixtures do not line up: 582 unique cassette references, 366 fixture YAML files, 241 referenced cassettes without fixture files, and 75 cassette files containing HTTP error status codes.
- Coverage signals conflict: `schema/coverage_baseline.json` reports CCD 100% and Chemi 98.5%, while committed badge JSON reports CCD 79.3% and Chemi 75.5%.

This branch intentionally does not change package runtime code, generated wrappers, cassettes, roxygen output, schemas, or workflows.

## Sources Reviewed

- Bean `ComptoxR-epem` and GitHub issue `#179`.
- `NAMESPACE`, `DESCRIPTION`, `R/`, `man/`, and `tests/testthat`.
- `dev/test_manifest.json`, `dev/TESTING_GUIDE.md`, `dev/generate_tests.R`, and `dev/check_cassette_health.R`.
- `tests/testthat/helper-vcr.R`, `tests/testthat/helper-api.R`, and `tests/testthat/setup.R`.
- `.github/workflows/*.yml`, `codecov.yml`, `.github/badges/*.json`, and `schema/coverage_baseline.json`.
- `.planning/codebase/TESTING.md` and `.planning/MILESTONES.md` for historical testing claims.

The reproducible audit data is in `dev/reports/unit_test_readiness_audit.json`.

## Current Inventory

| Area | Current count |
| --- | ---: |
| `NAMESPACE` exports | 393 |
| Non-operator exported functions | 391 |
| S3 methods in `NAMESPACE` | 4 |
| `R/*.R` files | 320 |
| `man/*.Rd` files | 437 |
| Top-level `tests/testthat/test-*.R` files | 233 |
| Test helpers in `tests/testthat` | 4 |
| Test generator/tool helper files | 3 |
| YAML fixture files under `tests/testthat/fixtures` | 366 |
| GitHub workflow files | 14 |

Test files by current prefix:

| Prefix | Test files |
| --- | ---: |
| `chemi` | 109 |
| `ct` | 104 |
| `eco` | 4 |
| `genra` | 3 |
| `pubchem` | 3 |
| `generic` | 2 |
| `tox` | 2 |
| Other singleton prefixes | 6 |

Exported functions by current prefix:

| Prefix | Exported functions |
| --- | ---: |
| `chemi` | 187 |
| `ct` | 136 |
| `dss` | 9 |
| `eco` | 8 |
| `toxval` | 8 |
| `cc` | 5 |
| `cts` | 5 |
| Other prefixes | 33 |

## Generator And Manifest Readiness

`dev/test_manifest.json` is not a current inventory:

| Check | Count |
| --- | ---: |
| Manifest files | 45 |
| Manifest files present in `tests/testthat` | 4 |
| Manifest files missing from `tests/testthat` | 41 |
| Current test files absent from manifest | 229 |

Current generated-test shape:

| Check | Count |
| --- | ---: |
| Test files with generated-test header | 209 |
| Test files without generated-test header | 24 |
| Generated tests calling backticked endpoint names with hyphens | 58 |
| Tests with generated "works without parameters" case | 99 |

The backticked hyphen-call pattern is a blocker for treating generated tests as public API coverage. Example shape from current tests:

```r
result <- `ct_chemical_by-exact-formula`()
```

That endpoint-style symbol is not an exported R function name. The generator needs to map endpoint slugs to exported wrapper names before bulk test generation or cassette work will be reliable.

## Export Coverage Signals

The audit used two conservative comparisons:

- Named test file match: `test-<export>.R`, normalizing hyphens to underscores in the test stem.
- Literal test reference: lexical references to exported function names inside top-level `test-*.R` files. This can include comments, so it is only a signal, not proof of behavioral coverage.

| Check | Count |
| --- | ---: |
| Non-operator exported functions | 391 |
| Exports with named test file | 138 |
| Exports without named test file | 253 |
| Exports with literal test reference | 175 |
| Exports without literal test reference | 216 |

Selected service-family signal:

| Family | Exports | Named test files | Literal test references | Without literal test reference |
| --- | ---: | ---: | ---: | ---: |
| `chemi` | 187 | 109 | 110 | 77 |
| `ct` | 136 | 19 | 21 | 115 |
| `cc` | 5 | 0 | 1 | 4 |
| `dss` | 9 | 0 | 8 | 1 |
| `eco` | 8 | 0 | 8 | 0 |
| `toxval` | 8 | 0 | 8 | 0 |
| `epi` | 2 | 0 | 0 | 2 |
| `pubchem` | 4 | 3 | 3 | 1 |
| `genra` | 4 | 3 | 4 | 0 |

Interpretation:

- Cheminformatics has the largest apparent test-file footprint, but still leaves 77 exported functions without literal test references.
- CT has the biggest readiness gap: 136 exports, only 21 literal references, and many generated endpoint-style tests that do not call exported symbols.
- Local data/service families need a different test strategy than API wrappers: mocked filesystem/database/provider tests for deterministic CRAN behavior.

## Fixtures And Cassette Hygiene

| Check | Count |
| --- | ---: |
| Test files using `vcr::use_cassette()` | 218 |
| Unique literal cassette references | 582 |
| YAML fixture files | 366 |
| Referenced cassettes with fixture files | 341 |
| Referenced cassettes missing fixture files | 241 |
| Fixture files not referenced by literal test calls | 25 |
| Fixture YAML parse errors from audit scan | 0 |
| Fixture files with HTTP status >= 400 | 75 |

This does not mean every missing fixture is automatically bad: some cassettes may be intended for re-recording or generated tests that are not currently runnable. It does mean cassette state cannot be treated as CRAN-ready until there is a policy for missing references, expected error cassettes, and live recording boundaries.

## CI And Coverage

Current workflow signals:

| Check | Count |
| --- | ---: |
| Workflow files | 14 |
| Workflows running `devtools::test()` | 2 |
| Workflows running targeted `testthat::test_file()` | 1 |
| Workflows running package checks | 4 |
| Workflows using `covr::` | 3 |
| Workflows setting `ctx_api_key` from secrets | 4 |

Current coverage signals:

| Source | Signal |
| --- | --- |
| `codecov.yml` project | Auto target, 1% threshold |
| `codecov.yml` patch | 80% target, 0% threshold |
| `.github/workflows/coverage-check.yml` | 75% minimum, warn-only |
| `.github/workflows/pipeline-tests.yml` | R package coverage >= 75%, enforced |
| `.github/workflows/pipeline-tests.yml` | `dev/endpoint_eval` coverage >= 80%, enforced |
| `schema/coverage_baseline.json` | CCD 100%, Chemi 98.5%, timestamp 2026-06-24T10:09:06Z |
| `.github/badges/ccd-coverage.json` | CCD 79.3% |
| `.github/badges/chemi-coverage.json` | Chemi 75.5% |

Fresh line coverage was not run for this audit branch because that would run the test suite and likely exercise the unresolved VCR/API-key surface. The readiness work needs to decide which coverage signal is authoritative for CRAN release: line coverage, endpoint-wrapper coverage, or both.

## Stale Or Conflicting Documentation

- `.planning/codebase/TESTING.md` claims 323 function-specific test files and 323 generated files. Current top-level `tests/testthat/test-*.R` count is 233, with 209 generator-header files.
- `dev/test_manifest.json` was updated on 2026-03-09 and lists 45 generated files. Current checkout has only 4 of those files present and 229 current test files absent from the manifest.
- `dev/TESTING_GUIDE.md` says CI has no API key. Current workflows set `ctx_api_key` from `CTX_API_KEY` secrets in four workflow files. CRAN and fork behavior still need explicit offline boundaries.
- `schema/coverage_baseline.json` and `.github/badges/*.json` report different endpoint coverage values, so coverage ownership is unclear.

## Gap Categories

1. Generator infrastructure
   - Fix endpoint slug to exported function-name mapping.
   - Regenerate or retire `dev/test_manifest.json`.
   - Add generator tests proving generated test calls resolve to exported package functions.

2. CRAN-safe and offline tests
   - Define default CRAN test path that does not require secrets, live network, local downloads, or cassette recording.
   - Add explicit `skip_on_cran()` and secret/network skips for integration-only tests.
   - Keep offline replay tests separate from live re-recording workflows.

3. API wrapper coverage
   - Prioritize CT wrappers first because 115 of 136 CT exports have no literal test reference.
   - Then close Chemi wrapper gaps and endpoint-specific post-processing assertions.
   - Require exported function references, not endpoint-style backticked calls.

4. Local data and service tests
   - Add deterministic tests for DSS, ECOTOX, ToxVal, EPI, and CTS behavior using mocks, fixtures, or small local test data.
   - Avoid tests that depend on installed large local databases unless they are skipped outside explicit integration paths.

5. Utility and internal tests
   - Add focused unit tests for exported parsing, formatting, request construction, and environment helpers.
   - Prefer mocked `httr2` and local data tests over VCR where behavior is package logic rather than external API contract.

6. Cassette hygiene
   - Run safety, parse, and HTTP status checks before accepting cassette changes.
   - Decide whether error-response cassettes are expected negative fixtures or bad recordings.
   - Do not re-record cassettes in bulk until generated tests call real exported functions.

7. CI coverage gates
   - Define one blocking CRAN-readiness workflow and one integration workflow.
   - Reconcile line coverage, endpoint coverage, and badge/baseline ownership.
   - Make secret-dependent jobs explicit and non-authoritative for CRAN pass/fail.

## Roadmap Expansion Applied

Applied on 2026-06-26 after review approval.

- GitHub issue `#179` is now the roadmap index for the unit-test readiness epic.
- Root epic bean `ComptoxR-8z9q` and triage bean `ComptoxR-epem` mirror the roadmap index.
- The roadmap now has 8 sub-epic GitHub issues and 50 leaf task issues.
- The concrete issue tree is recorded in `dev/reports/unit_test_readiness_issue_tree.json`.
- Beans cannot parent an epic under another epic in this checkout, so sub-epic beans are parented to the CRAN milestone bean and tagged back to `ComptoxR-8z9q`; leaf task beans are parented under their sub-epic beans.

| Sub-epic | Bean | Leaf issues | Triage role |
| --- | --- | --- | --- |
| `#180` Test inventory authority for CRAN readiness | `ComptoxR-wsxo` | `#188`-`#192` | Make the inventory reproducible and authoritative before later gates depend on it. |
| `#181` Generated test correctness for exported API calls | `ComptoxR-sdq2` | `#193`-`#198` | Fix generator correctness before bulk regeneration or cassette re-recording. |
| `#182` CRAN-safe offline test lane | `ComptoxR-issc` | `#199`-`#204` | Define the no-secret, no-network, no-recording test contract. |
| `#183` Cassette hygiene and replayability | `ComptoxR-fb6p` | `#205`-`#211` | Classify fixture state and cassette health before re-recording. |
| `#184` API wrapper test coverage by service family | `ComptoxR-v6pu` | `#212`-`#221` | Close wrapper gaps by rubric, CT, Chemi, and smaller service families. |
| `#185` Local data and local service test coverage | `ComptoxR-ccet` | `#222`-`#227` | Cover DSS, ECOTOX, ToxVal, EPI, Plumber, and local fixture policy. |
| `#186` Utility and request-helper unit coverage | `ComptoxR-bmy9` | `#228`-`#232` | Add deterministic tests for utilities, environment helpers, and request helpers. |
| `#187` CI coverage gates and CRAN release signoff | `ComptoxR-yur4` | `#233`-`#237` | Reconcile coverage ownership, split CI lanes, enforce checks, and close the gate. |

## CRAN Readiness Criteria

The unit-test readiness epic should be considered complete only when all of these are true:

- All CRAN-run tests pass without a real `ctx_api_key`, live EPA services, local database downloads, or cassette recording.
- Tests requiring secrets, network, production APIs, or cassette recording are explicitly skipped on CRAN and isolated from default CRAN checks.
- Every exported function has at least one intentional test reference or a documented exclusion.
- Generated endpoint tests call exported R function names, not endpoint slugs.
- `dev/test_manifest.json` is regenerated to match `tests/testthat` or retired in favor of a documented authoritative inventory.
- All committed cassettes pass secret safety checks, YAML parse checks, and the agreed policy for error-response cassettes.
- CI has one blocking CRAN-readiness workflow and one integration workflow with explicit ownership of coverage thresholds and badges.

## Validation Status

Validation performed:

- `Rscript` JSON parse and Markdown total check: passed. Selected headline totals in this report match `dev/reports/unit_test_readiness_audit.json`.
- `Rscript` issue-tree parse: passed. `dev/reports/unit_test_readiness_issue_tree.json` contains 8 sub-epics, 50 leaf tasks, and no missing task bean IDs.
- GitHub milestone refetch: passed. `Now: CRAN Release Readiness` contains 59 open items: roadmap issue `#179`, 8 sub-epics, and 50 leaf tasks.
- `beans check`: passed.
- `Rscript dev/check_cassette_health.R`: failed read-only because 75 cassettes contain HTTP error responses. The same run reported 0 API-key safety issues and 0 YAML parse errors across 366 cassettes.
- Full `devtools::test()` was not run because this branch is audit-only and does not change runtime package behavior.
