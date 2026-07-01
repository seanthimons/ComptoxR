---
issue: 236
bean: ComptoxR-gljo
parent_issue: 187
parent_bean: ComptoxR-yur4
milestone: "Now: CRAN Release Readiness"
status: active-checklist
last_updated: 2026-07-01
---

# Final Unit-Test Readiness Signoff Checklist

This checklist is the release-manager index for the CRAN-readiness work. It maps each readiness criterion to the
tracker that owns it, the command or file that provides objective evidence, and the current evidence status.

## Current Merge Under Review

| Field | Value |
| --- | --- |
| Branch | `integration` |
| Merge commit | `91e85a7 refactor: merge curation primitive relocation into integration` |
| Merged branch | `refactor/relocate-curation-primitives` |
| Package version | `1.5.0` |
| Local R | `4.5.1` on `x86_64-w64-mingw32` |

## Readiness Criteria

| Criterion | Tracker | Command or evidence | Evidence status |
| --- | --- | --- | --- |
| Generated wrapper contract tests are current and validate exported wrapper calls, not endpoint slugs. | #181 closed; #193-#197 closed; #248 / `ComptoxR-9vay` | `Rscript dev/generate_tests.R --check`; `tests/testthat/test-generate_tests_pipeline.R`; `tests/testthat/test-stub_generation_call_shape.R` | Pass on 2026-07-01. `generate_tests.R --check` discovered 328 exported API wrappers and reported generated tests current. |
| CRAN-safe tests pass without a real `ctx_api_key`, live EPA services, local database downloads, or cassette recording. | #182 closed; #248 / `ComptoxR-9vay` | `Rscript dev/cran_readiness.R`; `.github/workflows/cran-readiness.yml`; `dev/cran_readiness.R` unsets `ctx_api_key` and sets CRAN-safe env vars | Pass on 2026-07-01. Parallel CRAN-safe tests: 3379 pass, 47 expected skips. Sequential state-sensitive tests: 177 pass, 0 skips. |
| Export inventory has no gaps after documented exclusions. | #180 closed; #188-#191 closed; #238 closed | `Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps --output <temp-json>` | Pass on 2026-07-01. 386 function exports, 0 export gaps after exclusions, 0 VCR test files, VCR classification status ok. |
| `dev/test_manifest.json` is retired and not a readiness authority. | #180 closed; #189 closed | `dev/reports/unit_test_readiness_audit.json`; `dev/TESTING_GUIDE.md`; `.planning/codebase/TESTING.md` | Complete. The audit source records the manifest as absent, retired, and replaced by the readiness audit. |
| Replay/fixture tests use committed fixtures only and do not perform live cassette recording during CRAN-safe validation. | #183 / `ComptoxR-fb6p`; #248 / `ComptoxR-9vay` | `dev/vcr_test_classification.json`; `Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps`; `tests/README.md` VCR policy | Current audit reports 0 VCR test files and classification status ok. Cassette-health policy epic remains open. |
| Live recording is explicit opt-in only and requires a real `ctx_api_key`. | #183 / `ComptoxR-fb6p`; #234 / `ComptoxR-zj5b` | `.github/workflows/record-cassettes.yml`; `.github/workflows/README.md`; `dev/rerecord_cassettes.R --record-live`; `dev/test_generation/07_token_preflight.R` | Complete for lane separation. Broader cassette epic remains open. |
| CRAN-readiness CI is separated from live integration or recording workflows. | #234 / `ComptoxR-zj5b` | `.github/workflows/cran-readiness.yml`; `.github/workflows/README.md`; `.planning/codebase/TESTING.md`; `dev/TESTING_GUIDE.md`; `tests/README.md` | Complete. `cran-readiness.yml` does not map `CTX_API_KEY` or `ctx_api_key`; live recording is isolated to explicit workflows/scripts. |
| Coverage and badge ownership are reconciled before using coverage as a release gate. | #233 / `ComptoxR-ad5f`; #235 / `ComptoxR-effg` | `codecov.yml`; `.github/badges/*.json`; `schema/coverage_baseline.json`; coverage workflows | Open. This is a policy/gate decision and is not closed by local CRAN-safe test evidence. |
| Blocking coverage and cassette policy checks are added where required. | #235 / `ComptoxR-effg` | Coverage workflow state, cassette policy checks, final gate issue #237 | Open. Depends on #233 and remaining policy decisions. |
| Final source tarball builds and passes `R CMD check --as-cran` with 0 ERROR, 0 WARNING, and no unexplained CRAN-significant NOTE. | #247 / `ComptoxR-fpl7` | `R.exe CMD build . --no-resave-data`; `R.exe CMD check --as-cran --output="$env:TEMP\comptoxr-rcheck-postmerge" ComptoxR_1.5.0.tar.gz`; `00check.log` | Pass on 2026-07-01. Build exit 0. Check exit 0 with 0 ERROR, 0 WARNING, 1 NOTE: `New submission`, which is expected and CRAN-explainable for the first submission. Check tests: 3441 pass, 59 expected skips. |
| CRAN policy cleanup is complete: URL, spelling, DESCRIPTION, `cran-comments.md`, and tarball contents review. | #250 / `ComptoxR-r3ku` | `urlchecker::url_check()`; `spelling::spell_check_package()`; `DESCRIPTION`; `.Rbuildignore`; source tarball contents | Attempted. URL check passes for 312 URLs, obvious typos fixed, `DESCRIPTION` has `URL`, `BugReports`, and `Language`, and tarball review found no unwanted local-only paths across 1155 files. Spelling review still reports 351 domain/review rows and `cran-comments.md` is not created yet, so #250 remains open. |
| Cross-platform CRAN check evidence is collected. | #249 / `ComptoxR-e5op` | External CI or platform check logs | Open. Requires external platform evidence and is not closed by local Windows validation. |
| Release dispatch is performed only after check evidence is accepted. | #244 / `ComptoxR-tmi9` | Release workflow dispatch and release notes | Open. This is a later release action, not part of the local merge. |
| Development gate closes only after all readiness criteria pass or are explicitly waived. | #237 / `ComptoxR-tmx1`; parent epics #179 and #187 | This checklist plus issue closeout comments | Open. Terminal gate remains open until remaining review-bound and external gates are resolved. |

## Commands Run Before This Checklist

```powershell
git fetch origin
beans check
Rscript dev/generate_tests.R --check
Rscript -e "testthat::test_file('tests/testthat/test-cran_tarball_test_paths.R')"
Rscript -e "testthat::test_file('tests/testthat/test-stub_generation_call_shape.R')"
Rscript -e "testthat::test_file('tests/testthat/test-exported_utility_contracts.R')"
Rscript -e "testthat::test_file('tests/testthat/test-generate_tests_pipeline.R')"
Rscript -e "testthat::test_file('tests/testthat/test-unit_test_readiness_audit.R')"
Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps --output "$env:TEMP\comptoxr-unit-readiness-audit.json"
Rscript dev/cran_readiness.R
git merge --no-ff refactor/relocate-curation-primitives -m "refactor: merge curation primitive relocation into integration"
Rscript -e "urlchecker::url_check()"
Rscript -e "spelling::spell_check_package()"
R.exe CMD build . --no-resave-data
R.exe CMD check --as-cran --output="$env:TEMP\comptoxr-rcheck-postmerge" ComptoxR_1.5.0.tar.gz
```

## Current Closeout Decision

- Close #234 / `ComptoxR-zj5b`, because the no-secret CRAN-readiness lane and live-recording split are documented and implemented.
- Close #236 / `ComptoxR-gljo` after this checklist is committed, because it maps every readiness criterion to a tracker and evidence source.
- Close #248 / `ComptoxR-9vay`, because the post-merge generated-test check and `dev/cran_readiness.R` pass.
- Close #247 / `ComptoxR-fpl7`, because the post-merge source tarball builds and `R CMD check --as-cran` exits 0 with 0 ERROR, 0 WARNING, and only the expected `New submission` NOTE.
- Keep #250 / `ComptoxR-r3ku` open unless the remaining spelling review, `cran-comments.md`, and tarball-content review are completed without pending policy work.
- Keep #233, #235, #237, #244, #249, #179, and #187 open for their remaining policy, external, release, or parent-gate responsibilities.
