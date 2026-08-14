# GitHub Actions Workflows

This directory contains CI, coverage, data, release, and manual recording workflows. Testing workflows follow the same three-lane model documented in `dev/TESTING_GUIDE.md`, `.planning/codebase/TESTING.md`, and `tests/README.md`.

## Test Lanes

- CRAN-safe unit/contract tests: no real `ctx_api_key`, no live network dependency, no local database requirement, and no cassette recording. This lane is active when `COMPTOXR_CRAN_SAFE_TESTS=true` or when `NOT_CRAN` is anything other than `true`.
- Replay/fixture integration tests: committed fixtures only. These tests may replay existing fixtures but must not record new responses.
- Live recording tests: explicit opt-in only, require a real `ctx_api_key`, and run through isolated entrypoints such as the Record VCR Cassettes workflow or `Rscript dev/rerecord_cassettes.R --record-live`.

Tests that need external services should use `skip_if_offline()`, `skip_if_no_key()`, or `skip_if_cran_safe_external()` so CRAN-safe runs do not depend on secrets, network access, local downloads, or production APIs.

## Package Build And Release Workflows

### `build-package.yaml`

Manual artifact-only workflow named Build Package Artifact.

- Builds the source package from the selected workflow branch.
- Uploads the tarball as a workflow-run artifact retained for 14 days.
- Does not create or modify a GitHub Release.

### `publish-rolling-package.yaml`

Manual rolling prerelease workflow named Publish Rolling Package.

- Builds the source package from `main`.
- Creates the `package-latest` prerelease when it does not exist.
- Moves the rolling tag to the exact `main` commit used for each build.
- Replaces the matching source tarball asset on later runs.
- Does not affect GitHub's latest stable release selection.

### `publish-integration-package.yaml`

Automatic bleeding-edge prerelease workflow named Publish Integration Package.

- Runs on pushes to `integration` and by manual dispatch.
- Requires a dev-suffixed `DESCRIPTION` version such as `1.6.0.9000`.
- Builds SHA-stamped source, Windows, and macOS package assets.
- Uploads assets to the `integration-latest` prerelease.
- Moves the `integration-latest` tag to the exact integration commit only after all assets build.
- Removes stale `ComptoxR_*` rolling assets after a successful build.
- Does not affect immutable versioned releases or GitHub's latest stable release selection.

### `release.yaml`

Manual stable-release workflow named Release.

- Defaults to a semantic patch bump, such as v1.5.0 to v1.5.1.
- Checks the package before pushing release commits and the version tag.
- Creates an immutable versioned release with the source tarball attached.
- Refuses to overwrite an existing version tag or release.

Existing stable release assets should only be replaced by rebuilding the exact
tagged source. Changed package code requires a new versioned release or the
rolling `package-latest` prerelease.

## Main Testing Workflows

### `cran-readiness.yml`

Blocking CRAN-safe readiness workflow for pull requests and manual runs.

- Sets `COMPTOXR_CRAN_SAFE_TESTS=true` and `NOT_CRAN=false`.
- Runs generated-test smoke checks.
- Runs `Rscript dev/cran_readiness.R`.
- Does not rely on a real `ctx_api_key`, local database downloads, live APIs, or cassette recording.

### `R-CMD-check.yml`

Standard package check on pull requests and pushes to `main`.

### `test-coverage.yml`

Cross-platform package test and coverage workflow.

- Runs on Ubuntu, Windows, and macOS for release and devel R.
- Runs `devtools::test()`.
- Calculates and uploads coverage on Ubuntu release R.
- Must not auto-record cassettes from production APIs.

### `coverage-check.yml`

Informational coverage workflow.

- Calculates package coverage and comments on pull requests.
- Warns when coverage is below the target threshold.
- Does not block merges on coverage percentage.
- Must not auto-record cassettes from production APIs.

### `schema-check.yml`

Scheduled and manual schema update workflow.

- Downloads the CompTox Dashboard, Cheminformatics, and EPI Suite schemas.
- Reports `ok` and a comma-separated `failed_families` list from the download
  step.
- Handles each family separately. A failure does not stop the other downloads
  or the later schema checks.
- Validates the EPI Suite response before it writes the schema. If the request
  or validation fails, the workflow warns and keeps the last valid committed
  EPI Suite schema.
- Creates an automated pull request when valid schema changes are present.

### `record-cassettes.yml`

Manual live-recording workflow named Record VCR Cassettes.

- Triggered only with `workflow_dispatch`.
- Requires the `CTX_API_KEY` secret, exposed to R as `ctx_api_key`.
- Runs `dev/rerecord_cassettes.R --record-live`.
- Supports `priority`, `all`, and `failures` modes.
- Uploads recorded fixtures and logs as workflow artifacts.

This workflow is the CI-side path for intentional live recording. Missing cassettes must not make ordinary CI hit production APIs or record responses automatically.

## Readiness Artifacts

The canonical test inventory is `dev/reports/unit_test_readiness_audit.json`, produced and validated by:

```bash
Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps
```

For documentation-only validation, write to a temporary path with `--output <temp-path-outside-repo>` instead of regenerating the canonical report.

`dev/vcr_test_classification.json` is the VCR classification gate. Every current test file containing `vcr::use_cassette()` must be classified there, and stale classifications fail the readiness audit. The current classification set is empty because the current branch has no VCR test files.

Before accepting any cassette changes:

```r
source("tests/testthat/helper-vcr.R")
check_cassette_errors()
check_cassette_safety()
```

## Secrets

### `CTX_API_KEY`

CompTox Dashboard API key. It is required only for intentional live recording through `record-cassettes.yml` or a local `dev/rerecord_cassettes.R --record-live` run. Routine CRAN-safe testing must pass without it.

### `CODECOV_TOKEN`

Optional Codecov upload token used by coverage workflows.

## Local Equivalents

Run targeted tests during development:

```r
testthat::test_file("tests/testthat/test-generic_request.R")
devtools::test(filter = "generic_request")
```

Run the readiness audit:

```bash
Rscript dev/unit_test_readiness_audit.R --check-exports --fail-on-gaps
```

Run the CRAN-safe readiness lane when a change has broad package impact:

```bash
Rscript dev/cran_readiness.R
```

Record cassettes only when explicitly required:

```bash
Rscript dev/rerecord_cassettes.R --record-live --all
Rscript dev/rerecord_cassettes.R --record-live --failures
```

## Troubleshooting

### A CRAN-safe run tries to call an external service

Add or fix the appropriate skip helper: `skip_if_offline()`, `skip_if_no_key()`, or `skip_if_cran_safe_external()`. The CRAN-safe lane must not require a real `ctx_api_key`, live network access, local database downloads, or cassette recording.

### A replay test is missing a cassette

Do not make CI re-record from production. Either adjust the test to stay in the CRAN-safe unit/contract lane, or run an intentional live-recording task through the Record VCR Cassettes workflow or `dev/rerecord_cassettes.R --record-live`, then inspect the artifact and run cassette safety checks before accepting fixture changes.

### Live recording fails with "No real API key"

Set a real `ctx_api_key` locally or configure the `CTX_API_KEY` GitHub secret for the manual Record VCR Cassettes workflow. Dummy, placeholder, empty, and redacted-looking values are rejected.

## Resources

- [GitHub Actions for R](https://github.com/r-lib/actions)
- [R Packages: R CMD check](https://r-pkgs.org/R-CMD-check.html)
- [vcr for R](https://docs.ropensci.org/vcr/)
- [Codecov Documentation](https://docs.codecov.com/)
