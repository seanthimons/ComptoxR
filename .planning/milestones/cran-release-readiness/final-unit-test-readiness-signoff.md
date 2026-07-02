---
issue: 236
bean: ComptoxR-gljo
parent_issue: 187
parent_bean: ComptoxR-yur4
milestone: "Now: CRAN Release Readiness"
status: release-signoff-ready
last_updated: 2026-07-02
---

# Final Unit-Test Readiness Signoff Checklist

This checklist is the release-manager index for the CRAN-readiness work. It maps each readiness criterion to the
tracker that owns it, the command or file that provides objective evidence, and the current evidence status.

## Current Merge Under Review

| Field | Value |
| --- | --- |
| Branch | `integration` |
| Release-readiness commit | `8d12412 fix(cran): complete policy cleanup gates` |
| Prior integration merge | `91e85a7 refactor: merge curation primitive relocation into integration` |
| Package version | `1.5.0` |
| Local R | `4.5.1` on `x86_64-w64-mingw32` |
| CI R-CMD-check run | <https://github.com/seanthimons/ComptoxR/actions/runs/28600679813> |
| CI CRAN-readiness run | <https://github.com/seanthimons/ComptoxR/actions/runs/28600679829> |

## Readiness Criteria

| Criterion | Tracker | Command or evidence | Evidence status |
| --- | --- | --- | --- |
| Generated wrapper contract tests are current and validate exported wrapper calls, not endpoint slugs. | #181 closed; #193-#197 closed; #248 / `ComptoxR-9vay` | `Rscript dev/generate_tests.R --check`; `tests/testthat/test-generate_tests_pipeline.R`; `tests/testthat/test-stub_generation_call_shape.R` | Pass on 2026-07-02. `generate_tests.R --check` discovered 328 exported API wrappers and reported generated tests current locally and in CI. |
| CRAN-safe tests pass without a real `ctx_api_key`, live EPA services, local database downloads, or cassette recording. | #182 closed; #248 / `ComptoxR-9vay` | `Rscript dev/cran_readiness.R`; `.github/workflows/cran-readiness.yml`; `dev/cran_readiness.R` unsets `ctx_api_key` and sets CRAN-safe env vars | Pass on 2026-07-02. Local parallel CRAN-safe tests: 3379 pass, 47 expected skips. Sequential state-sensitive tests: 177 pass, 0 skips. CI CRAN Readiness run 28600679829 passed. |
| Export inventory has no gaps after documented exclusions. | #180 closed; #188-#191 closed; #238 closed | `Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps --output <temp-json>` | Pass on 2026-07-02. 386 function exports, 0 export gaps after exclusions, 0 VCR test files, VCR classification status ok. CI CRAN Readiness reports the same 0-gap status. |
| `dev/test_manifest.json` is retired and not a readiness authority. | #180 closed; #189 closed | `dev/reports/unit_test_readiness_audit.json`; `dev/TESTING_GUIDE.md`; `.planning/codebase/TESTING.md` | Complete. The audit source records the manifest as absent, retired, and replaced by the readiness audit. |
| Replay/fixture tests use committed fixtures only and do not perform live cassette recording during CRAN-safe validation. | #183 / `ComptoxR-fb6p`; #248 / `ComptoxR-9vay`; #235 / `ComptoxR-effg` | `dev/vcr_test_classification.json`; `Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps`; `Rscript dev/check_cassette_health.R`; `tests/README.md` VCR policy | Complete for CRAN. Audit reports 0 VCR test files and classification status ok. Cassette health reports 0 cassettes, 0 safety issues, 0 HTTP error responses, and 0 parse errors locally and in CI. |
| Live recording is explicit opt-in only and requires a real `ctx_api_key`. | #183 / `ComptoxR-fb6p`; #234 / `ComptoxR-zj5b` | `.github/workflows/record-cassettes.yml`; `.github/workflows/README.md`; `dev/rerecord_cassettes.R --record-live`; `dev/test_generation/07_token_preflight.R` | Complete for lane separation. Broader cassette epic remains open. |
| CRAN-readiness CI is separated from live integration or recording workflows. | #234 / `ComptoxR-zj5b` | `.github/workflows/cran-readiness.yml`; `.github/workflows/README.md`; `.planning/codebase/TESTING.md`; `dev/TESTING_GUIDE.md`; `tests/README.md` | Complete. `cran-readiness.yml` does not map `CTX_API_KEY` or `ctx_api_key`; live recording is isolated to explicit workflows/scripts. |
| Coverage and badge ownership are reconciled before using coverage as a release gate. | #233 / `ComptoxR-ad5f`; #235 / `ComptoxR-effg` | `codecov.yml`; `.github/badges/*.json`; `schema/coverage_baseline.json`; coverage workflows | Waived as a CRAN-blocking gate for v1.5.0. Numeric endpoint or line coverage is informational for this release; generated tests current, export audit 0 gaps, CRAN-safe tests, and cassette health are blocking. |
| Blocking coverage and cassette policy checks are added where required. | #235 / `ComptoxR-effg` | `.github/workflows/cran-readiness.yml`; `Rscript dev/check_cassette_health.R`; `Rscript dev/cran_readiness.R` | Complete for CRAN. `cran-readiness.yml` now blocks on cassette health plus generated-test/export/CRAN-safe readiness. Numeric coverage remains non-blocking for v1.5.0. |
| Final source tarball builds and passes `R CMD check --as-cran` with 0 ERROR, 0 WARNING, and no unexplained CRAN-significant NOTE. | #247 / `ComptoxR-fpl7` | `R.exe CMD build . --no-resave-data`; `R.exe CMD check --as-cran --output="$env:TEMP\comptoxr-rcheck-20260702-policy-2" ComptoxR_1.5.0.tar.gz`; `00check.log` | Pass on 2026-07-02. Build exit 0. Check exit 0 with 0 ERROR, 0 WARNING, 2 NOTEs: expected `New submission` and local `unable to verify current time` clock-verification NOTE. CI R-CMD-check run 28600679813 returned Status: OK on all three OSes. |
| CRAN policy cleanup is complete: URL, spelling, DESCRIPTION, `cran-comments.md`, and tarball contents review. | #250 / `ComptoxR-r3ku` | `urlchecker::url_check()`; `spelling::spell_check_package()`; `DESCRIPTION`; `.Rbuildignore`; `cran-comments.md`; source tarball contents | Complete on 2026-07-02. URL check passes for 312 URLs. Spelling reports no errors after real typo fixes and `inst/WORDLIST`. `cran-comments.md` exists and is excluded from the tarball. Tarball review found no local-only paths across 1,156 files. |
| Cross-platform CRAN check evidence is collected. | #249 / `ComptoxR-e5op` | GitHub Actions R-CMD-check matrix | Complete on 2026-07-02. Run 28600679813 passed on ubuntu-latest, windows-latest, and macos-latest with R 4.6.1 release. All jobs returned Status: OK. |
| Release dispatch is performed only after check evidence is accepted. | #244 / `ComptoxR-tmi9` | Release workflow dispatch and release notes | Open. This is a later release action, not part of the local merge. |
| Development gate closes only after all readiness criteria pass or are explicitly waived. | #237 / `ComptoxR-tmx1`; parent epics #179 and #187 | This checklist plus issue closeout comments | Ready to close after #233, #235, #249, and #250 closeout comments are posted. Remaining #244 release dispatch is a release action after gate closeout. |

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
Rscript dev/check_cassette_health.R
R.exe CMD build . --no-resave-data
R.exe CMD check --as-cran --output="$env:TEMP\comptoxr-rcheck-postmerge" ComptoxR_1.5.0.tar.gz
R.exe CMD check --as-cran --output="$env:TEMP\comptoxr-rcheck-20260702-policy-2" ComptoxR_1.5.0.tar.gz
gh workflow run R-CMD-check.yml --ref integration
gh workflow run cran-readiness.yml --ref integration
gh run watch 28600679813 --exit-status --interval 30
gh run watch 28600679829 --exit-status --interval 30
```

## Current Closeout Decision

- Close #234 / `ComptoxR-zj5b`, because the no-secret CRAN-readiness lane and live-recording split are documented and implemented.
- Close #236 / `ComptoxR-gljo` after this checklist is committed, because it maps every readiness criterion to a tracker and evidence source.
- Close #248 / `ComptoxR-9vay`, because the post-merge generated-test check and `dev/cran_readiness.R` pass.
- Keep #247 / `ComptoxR-fpl7` closed; the refreshed source tarball builds and `R CMD check --as-cran` exits 0 with 0 ERROR, 0 WARNING, the expected `New submission` NOTE, and a local clock-verification NOTE that is not package-specific.
- Close #233 / `ComptoxR-ad5f`, because numeric endpoint coverage is explicitly non-blocking for CRAN v1.5.0 and objective readiness gates are authoritative.
- Close #235 / `ComptoxR-effg`, because CRAN Readiness now blocks on generated tests, export audit, CRAN-safe tests, and cassette health; numeric coverage remains non-blocking for v1.5.0.
- Close #249 / `ComptoxR-e5op`, because the GitHub Actions R-CMD-check matrix passed on Linux, Windows, and macOS.
- Close #250 / `ComptoxR-r3ku`, because URL, spelling, `cran-comments.md`, DESCRIPTION, `.Rbuildignore`, and tarball-content review are complete.
- Close #237 / `ComptoxR-tmx1` after the four closeout comments above are posted, because the remaining readiness criteria are complete or explicitly waived.
- Keep #244 / `ComptoxR-tmi9` open until `integration` is merged to `main`, the release workflow is dispatched with `version_type=none`, and `v1.5.0` artifacts are verified.
- Keep #179 and #187 open until the release action is verified, then close them with links to this checklist and the release evidence.
