# Phase 14: Integration & CI - Research

**Researched:** 2026-01-30
**Domain:** R package integration testing, coverage measurement, and CI/CD with GitHub Actions
**Confidence:** HIGH

## Summary

Integration and CI testing for R packages follows established patterns in the R ecosystem, built on testthat 3.3.2, covr for coverage measurement, vcr for HTTP mocking, and r-lib/actions for GitHub Actions workflows. The key challenge for this phase is end-to-end verification of the stub generation pipeline using real production schemas, enforcing separate coverage thresholds for R/ code (rOpenSci requirement: ≥75%) and dev/ code (internal target: ≥80%), and blocking PRs when tests fail or coverage drops below thresholds.

The standard approach uses testthat's describe() blocks for hierarchical test organization, vcr cassettes to record real API interactions once and replay them in CI, covr::file_coverage() to measure specific directory coverage with .covrignore exclusions, and GitHub Actions workflows with r-lib/actions for dependency management and Codecov integration for PR-level coverage reporting with configurable thresholds.

**Primary recommendation:** Create a dedicated pipeline-tests.yml workflow that runs integration tests with real schemas from schema/ directory on PR events, uses covr to separately measure R/ and dev/ coverage with explicit threshold checks, uploads results to Codecov with codecov.yml configuration for PR status checks, and implements if: failure() artifacts + auto-issue creation for transparent failure handling.

## Standard Stack

The established libraries/tools for R package integration testing and CI:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| testthat | 3.3.2 | Testing framework | Industry standard for R packages, used by thousands of CRAN packages; supports BDD-style describe() blocks |
| covr | 2.0+ | Coverage measurement | Official r-lib coverage tool; integrates with Codecov; supports file_coverage() for specific directories |
| vcr | 2.1.0 | HTTP mocking | rOpenSci standard for recording/replaying HTTP interactions; prevents API rate limits in CI |
| r-lib/actions | v2 | GitHub Actions | Official R-core maintained actions; handles R setup, dependency installation, and package checks |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| withr | Latest | Test fixtures | Clean setup/teardown of test state; already added as Suggests dependency in Phase 12 |
| codecov-action | v4 | Coverage upload | Upload coverage to Codecov.io with token authentication |
| here | Latest | Path resolution | Reliable cross-platform path construction; already in Imports |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| vcr | httptest2 / webmockr | vcr is standard in rOpenSci ecosystem and better YAML format |
| r-lib/actions | Custom Docker | r-lib/actions maintained by R-core, handles edge cases, faster with RSPM |
| Codecov | Coveralls | Codecov has better GitHub integration and PR comments with threshold configuration |

**Installation:**
```bash
# Already in DESCRIPTION Suggests:
# testthat (>= 3.0.0), vcr, withr

# GitHub Actions setup in workflow YAML:
# - uses: r-lib/actions/setup-r@v2
# - uses: r-lib/actions/setup-r-dependencies@v2
# - uses: codecov/codecov-action@v4
```

## Architecture Patterns

### Recommended Test Structure
```
tests/testthat/
├── helper-vcr.R           # VCR configuration (exists)
├── helper-pipeline.R      # Pipeline sourcing utilities (exists)
├── test-pipeline-integration.R  # NEW: End-to-end integration tests
├── fixtures/
│   ├── _vcr/             # VCR cassettes (gitignored or committed)
│   │   ├── integration-ctx-hazard.yml
│   │   ├── integration-chemi-safety.yml
│   │   └── integration-epi-suite.yml
│   └── schemas/          # Minimal test schemas (exists)
└── test-*.R              # Unit tests (exist)
```

### Pattern 1: End-to-End Integration Test Structure
**What:** Full pipeline execution with real schemas, actual function calls, and VCR-mocked APIs
**When to use:** Verifying stub generation produces valid, executable R functions from production schemas
**Example:**
```r
# Source: testthat best practices + existing helper-pipeline.R pattern
describe("E2E: CompTox Dashboard Pipeline", {
  test_that("generates valid stubs from ctx-hazard-prod schema", {
    vcr::use_cassette("integration-ctx-hazard", {
      # Parse real production schema
      schema_path <- here::here("schema/ctx-hazard-prod.json")
      schema <- jsonlite::fromJSON(schema_path, simplifyVector = FALSE)

      # Generate stub (full pipeline execution)
      source_pipeline_files()
      stub <- build_function_stub(
        fn = "ct_hazard_test",
        endpoint = "/hazard",
        # ... extracted from schema
      )

      # Verify stub syntax
      expect_type(stub, "character")
      expect_true(grepl("ct_hazard_test <- function", stub))

      # Execute generated stub (with VCR recording API call)
      eval(parse(text = stub))
      result <- ct_hazard_test("DTXSID7020182")
      expect_s3_class(result, "data.frame")
    })
  })
})
```

### Pattern 2: Separate Coverage Measurement
**What:** Measure R/ and dev/ coverage independently with explicit thresholds
**When to use:** Enforcing different coverage standards for production code vs. dev scripts
**Example:**
```r
# Source: covr documentation + Phase 14 requirements
# In GHA workflow step:
- name: Check R/ coverage threshold (≥75%)
  run: |
    r_cov <- covr::file_coverage(
      source_files = list.files("R", pattern = "\\.R$", full.names = TRUE)
    )
    r_percent <- covr::percent_coverage(r_cov)

    cat(sprintf("R/ Coverage: %.2f%%\n", r_percent))

    if (r_percent < 75) {
      stop(sprintf("R/ coverage (%.2f%%) below 75%% threshold", r_percent))
    }
  shell: Rscript {0}

- name: Check dev/ coverage threshold (≥80%)
  run: |
    dev_cov <- covr::file_coverage(
      source_files = list.files("dev/endpoint_eval", pattern = "\\.R$", full.names = TRUE),
      test_files = list.files("tests/testthat", pattern = "^test-pipeline", full.names = TRUE)
    )
    dev_percent <- covr::percent_coverage(dev_cov)

    cat(sprintf("dev/endpoint_eval/ Coverage: %.2f%%\n", dev_percent))

    if (dev_percent < 80) {
      stop(sprintf("dev/ coverage (%.2f%%) below 80%% threshold", dev_percent))
    }
  shell: Rscript {0}
```

### Pattern 3: VCR Cassette Organization
**What:** Hierarchical naming for cassettes based on microservice and test type
**When to use:** Managing cassettes for multiple microservices with clear identification
**Example:**
```r
# Source: vcr documentation + rOpenSci best practices
# https://docs.ropensci.org/vcr/articles/vcr.html

# Naming convention: {test-type}-{microservice}-{endpoint}
vcr::use_cassette("integration-ctx-hazard", {
  # Test CompTox Dashboard hazard endpoint
})

vcr::use_cassette("integration-chemi-safety", {
  # Test Cheminformatics safety endpoint
})

vcr::use_cassette("integration-epi-fate", {
  # Test EPI Suite environmental fate endpoint
})

# Storage: tests/testthat/fixtures/_vcr/
# Committed to git after security review with check_cassette_safety()
```

### Pattern 4: GitHub Actions Workflow Dispatch for Cassette Re-recording
**What:** Manual workflow trigger to re-record VCR cassettes when APIs change
**When to use:** Updating cassettes without local API key, CI-driven re-recording
**Example:**
```yaml
# Source: GitHub Actions workflow_dispatch documentation
# https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions

on:
  workflow_dispatch:
    inputs:
      api_key:
        description: 'CompTox API Key'
        required: true
        type: secret

jobs:
  rerecord-cassettes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup R
        uses: r-lib/actions/setup-r@v2

      - name: Delete existing cassettes
        run: rm -rf tests/testthat/fixtures/_vcr/*.yml

      - name: Re-record cassettes
        env:
          ctx_api_key: ${{ inputs.api_key }}
        run: Rscript -e 'devtools::test(filter = "pipeline-integration")'

      - name: Commit updated cassettes
        run: |
          git config --local user.name "github-actions[bot]"
          git config --local user.email "github-actions[bot]@users.noreply.github.com"
          git add tests/testthat/fixtures/_vcr/
          git commit -m "chore: re-record VCR cassettes [skip ci]"
          git push
```

### Pattern 5: Failure Artifacts Upload
**What:** Capture generated stubs and error messages when E2E tests fail
**When to use:** Debugging test failures in CI without local reproduction
**Example:**
```yaml
# Source: GitHub Actions upload-artifact best practices
# https://github.com/actions/upload-artifact

- name: Run pipeline integration tests
  id: pipeline-tests
  run: Rscript -e 'devtools::test(filter = "pipeline-integration")'
  continue-on-error: true

- name: Upload failure artifacts
  if: always() && steps.pipeline-tests.outcome == 'failure'
  uses: actions/upload-artifact@v4
  with:
    name: pipeline-test-failures-${{ github.run_id }}
    path: |
      tests/testthat/failures/*.R
      tests/testthat/failures/*.txt
    retention-days: 5
```

### Anti-Patterns to Avoid
- **Running integration tests on every commit:** Integration tests are slow; run only on PR events, not push to feature branches
- **Single coverage threshold for R/ and dev/:** rOpenSci requires ≥75% for R/, but dev/ scripts should have higher standards (≥80%)
- **Hardcoding API keys in tests:** Always use vcr to record once with real API key, then replay from cassettes in CI without keys
- **Ignoring cassette security review:** Always inspect cassettes before committing to ensure API keys are filtered (helper-vcr.R already configures this)
- **Using source() instead of source_pipeline_files():** The codebase has a dependency-ordered sourcing function; use it

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Coverage threshold enforcement | Custom R script parsing covr output | covr::percent_coverage() + shell exit codes | covr provides accurate percentage calculation; shell exit codes natively fail CI |
| VCR cassette management | Custom HTTP recording | vcr package with filter_sensitive_data | vcr is rOpenSci standard, handles edge cases, YAML format human-readable |
| GitHub Actions R setup | Custom Docker image | r-lib/actions/setup-r@v2 + setup-r-dependencies@v2 | R-core maintained, handles CRAN/Bioconductor, uses RSPM for fast installs |
| Test file fixtures | Manual JSON files in tests/ | testthat::test_path() + here::here() for real schemas | Real production schemas are authoritative source; test fixtures for edge cases only |
| Codecov threshold checks | Parse Codecov API in GHA | codecov.yml with coverage.status.project.target | Codecov natively blocks PRs based on config; no custom scripting needed |
| Auto-issue creation | Custom octokit scripting | jayqi/failed-build-issue-action or dacbd/create-issue-action | Pre-built actions handle issue deduplication, templates, assignees |

**Key insight:** The R ecosystem has mature, well-tested solutions for package testing and CI. Custom solutions add maintenance burden and miss edge cases that established tools already handle. Use r-lib ecosystem tools for maximum compatibility.

## Common Pitfalls

### Pitfall 1: VCR Cassettes Not Replaying in CI
**What goes wrong:** Tests pass locally but fail in CI with "No cassette found" or HTTP connection errors
**Why it happens:** Cassettes not committed to git, or sensitive data filtering changes cassette structure
**How to avoid:**
- Always commit cassettes after first recording and security review
- Use `vcr::use_cassette()` with exact same name in test
- Check that filter_sensitive_data in helper-vcr.R doesn't break request matching
**Warning signs:** CI logs show "Real HTTP connection attempted" or "No cassette match found"

### Pitfall 2: Coverage Measurement Includes Wrong Files
**What goes wrong:** Coverage percentage includes test files, fixtures, or excluded directories
**Why it happens:** covr::package_coverage() defaults to all R/ files; doesn't separate dev/ from R/
**How to avoid:**
- Use covr::file_coverage() with explicit source_files argument
- Create .covrignore file to exclude dev/, tests/, data-raw/
- Verify coverage report shows only intended files before enforcing thresholds
**Warning signs:** Coverage percentage unexpectedly high or includes test file names in report

### Pitfall 3: Integration Tests Timeout in CI
**What goes wrong:** E2E tests exceed GitHub Actions default 6-hour job timeout
**Why it happens:** Parsing large schemas (ctx-chemical-prod.json is ~2MB) or network delays
**How to avoid:**
- Use vcr cassettes so no network calls in CI (first run records, subsequent replay)
- Test subset of production schemas (one per microservice: ctx, chemi, epi)
- Use `timeout-minutes: 30` in workflow job definition
**Warning signs:** Tests hang during schema parsing or stub generation steps

### Pitfall 4: Codecov Upload Fails with 401/403
**What goes wrong:** Coverage uploads succeed locally but fail in CI
**Why it happens:** CODECOV_TOKEN secret not configured or wrong repository permissions
**How to avoid:**
- Add CODECOV_TOKEN to repository secrets (not organization secrets)
- Use codecov-action@v4 with explicit `token: ${{ secrets.CODECOV_TOKEN }}`
- Set `fail_ci_if_error: true` to catch upload failures early
**Warning signs:** GHA logs show "Failed to upload coverage" but workflow continues

### Pitfall 5: Generated Stubs Fail R CMD check
**What goes wrong:** Integration tests pass but generated functions fail package checks
**Why it happens:** Generated roxygen docs have invalid @param or @return syntax
**How to avoid:**
- Include devtools::check() step in pipeline-tests.yml after stub generation
- Verify roxygen2 can parse generated documentation
- Test-generate at least one stub per request type (GET, POST, path params, body params)
**Warning signs:** R CMD check fails on "undocumented arguments" or "roxygen parsing error"

### Pitfall 6: Separate Coverage Thresholds Not Enforced
**What goes wrong:** Overall coverage meets 75% but dev/ code under 80% slips through
**Why it happens:** Single covr::package_coverage() call aggregates all code
**How to avoid:**
- Create two separate GHA steps: one for R/, one for dev/
- Each step calls covr::file_coverage() with specific directories
- Each step has explicit `if (percent < threshold) stop()` check
**Warning signs:** PR merges with green coverage badge but dev/ coverage declining

## Code Examples

Verified patterns from official sources:

### Example 1: Integration Test with Real Schema
```r
# Source: testthat 3.3.2 describe() + existing helper-pipeline.R pattern
# https://testthat.r-lib.org/reference/describe.html

describe("E2E: Cheminformatics Pipeline", {
  test_that("parses chemi-safety-prod schema and generates valid stub", {
    skip_on_cran()  # Integration tests only in CI

    vcr::use_cassette("integration-chemi-safety", {
      # Load real production schema
      schema <- jsonlite::fromJSON(
        here::here("schema/chemi-safety-prod.json"),
        simplifyVector = FALSE
      )

      # Source pipeline in dependency order
      source_pipeline_files()

      # Extract first endpoint from schema
      paths <- schema$paths
      first_path <- names(paths)[1]
      first_method <- names(paths[[first_path]])[1]

      # Generate stub using pipeline functions
      # (actual implementation would call parse_openapi_endpoint, etc.)
      stub <- build_function_stub(
        fn = "chemi_safety_test",
        endpoint = first_path,
        method = toupper(first_method),
        title = "Test Safety Endpoint",
        # ... rest of parameters from schema
        batch_limit = 200,
        config = list(wrapper_function = "generic_chemi_request")
      )

      # Verify stub is valid R code
      expect_type(stub, "character")
      expect_match(stub, "chemi_safety_test <- function")

      # Parse and execute stub
      tryCatch({
        eval(parse(text = stub))
      }, error = function(e) {
        # Capture stub on failure
        writeLines(stub, "tests/testthat/failures/failed-stub.R")
        writeLines(as.character(e), "tests/testthat/failures/error.txt")
        stop(e)
      })

      # Call generated function with VCR recording
      result <- chemi_safety_test("DTXSID7020182")

      # Verify result structure
      expect_true(!is.null(result))
      expect_s3_class(result, "data.frame")
    })
  })
})
```

### Example 2: Separate R/ and dev/ Coverage Measurement
```r
# Source: covr documentation - file_coverage()
# https://covr.r-lib.org/

# Step 1: Measure R/ coverage
r_source_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
r_test_files <- list.files(
  "tests/testthat",
  pattern = "^test-ct_|^test-chemi_|^test-util_",  # Package function tests only
  full.names = TRUE
)

r_cov <- covr::file_coverage(
  source_files = r_source_files,
  test_files = r_test_files
)

r_percent <- covr::percent_coverage(r_cov)
cat(sprintf("\nR/ Package Code Coverage: %.2f%%\n", r_percent))
print(r_cov)  # Shows per-file breakdown

# Step 2: Measure dev/endpoint_eval/ coverage
dev_source_files <- list.files(
  "dev/endpoint_eval",
  pattern = "\\.R$",
  full.names = TRUE
)
dev_test_files <- list.files(
  "tests/testthat",
  pattern = "^test-pipeline",  # Pipeline tests only
  full.names = TRUE
)

dev_cov <- covr::file_coverage(
  source_files = dev_source_files,
  test_files = dev_test_files
)

dev_percent <- covr::percent_coverage(dev_cov)
cat(sprintf("\ndev/endpoint_eval/ Pipeline Coverage: %.2f%%\n", dev_percent))
print(dev_cov)

# Step 3: Enforce thresholds
R_THRESHOLD <- 75
DEV_THRESHOLD <- 80

if (r_percent < R_THRESHOLD) {
  stop(sprintf("FAIL: R/ coverage (%.2f%%) below threshold (%d%%)",
               r_percent, R_THRESHOLD))
}

if (dev_percent < DEV_THRESHOLD) {
  stop(sprintf("FAIL: dev/ coverage (%.2f%%) below threshold (%d%%)",
               dev_percent, DEV_THRESHOLD))
}

cat("\n✓ Both coverage thresholds met\n")
```

### Example 3: GitHub Actions Pipeline Tests Workflow
```yaml
# Source: r-lib/actions examples + GitHub Actions best practices
# https://github.com/r-lib/actions/tree/v2/examples

name: Pipeline Integration Tests

on:
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      rerecord_cassettes:
        description: 'Re-record VCR cassettes'
        required: false
        type: boolean
        default: false

jobs:
  pipeline-tests:
    runs-on: ubuntu-latest
    name: Integration Tests

    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
      R_KEEP_PKG_SOURCE: yes
      ctx_api_key: ${{ secrets.CTX_API_KEY }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup R
        uses: r-lib/actions/setup-r@v2
        with:
          r-version: 'release'
          use-public-rspm: true

      - name: Setup R dependencies
        uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: |
            any::covr
            any::testthat
            any::vcr
            any::withr

      - name: Delete cassettes if re-recording
        if: github.event.inputs.rerecord_cassettes == 'true'
        run: rm -rf tests/testthat/fixtures/_vcr/*.yml

      - name: Run integration tests
        id: integration-tests
        run: |
          Rscript -e 'devtools::test(filter = "pipeline-integration")'
        continue-on-error: true

      - name: Check R/ coverage (≥75%)
        run: |
          r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
          r_cov <- covr::file_coverage(source_files = r_files)
          r_pct <- covr::percent_coverage(r_cov)

          cat(sprintf("\n📊 R/ Coverage: %.2f%%\n", r_pct))

          if (r_pct < 75) {
            cat(sprintf("❌ FAIL: R/ coverage below 75%% threshold\n"))
            quit(status = 1)
          }

          cat("✓ R/ coverage meets rOpenSci requirement\n")
        shell: Rscript {0}

      - name: Check dev/ coverage (≥80%)
        run: |
          dev_files <- list.files("dev/endpoint_eval", pattern = "\\.R$", full.names = TRUE)
          dev_tests <- list.files("tests/testthat", pattern = "^test-pipeline", full.names = TRUE)
          dev_cov <- covr::file_coverage(source_files = dev_files, test_files = dev_tests)
          dev_pct <- covr::percent_coverage(dev_cov)

          cat(sprintf("\n📊 dev/endpoint_eval/ Coverage: %.2f%%\n", dev_pct))

          if (dev_pct < 80) {
            cat(sprintf("❌ FAIL: dev/ coverage below 80%% threshold\n"))
            quit(status = 1)
          }

          cat("✓ dev/ coverage meets internal target\n")
        shell: Rscript {0}

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: ./coverage.xml
          fail_ci_if_error: false

      - name: Upload failure artifacts
        if: always() && steps.integration-tests.outcome == 'failure'
        uses: actions/upload-artifact@v4
        with:
          name: pipeline-failures-${{ github.run_id }}
          path: |
            tests/testthat/failures/*.R
            tests/testthat/failures/*.txt
          retention-days: 5

      - name: Create issue on main branch failure
        if: failure() && github.ref == 'refs/heads/main'
        uses: dacbd/create-issue-action@main
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          title: Pipeline tests failed on main branch
          body: |
            ## Pipeline Integration Test Failure

            The pipeline integration tests failed on the main branch.

            **Failed Run:** ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
            **Commit:** ${{ github.sha }}
            **Branch:** ${{ github.ref_name }}

            Please investigate the failure artifacts or re-run the workflow.
          labels: bug,CI,pipeline
          assignees: ${{ github.actor }}
```

### Example 4: Codecov Configuration
```yaml
# Source: Codecov documentation - Status Checks
# https://docs.codecov.com/docs/commit-status
# File: codecov.yml (repository root)

codecov:
  require_ci_to_pass: yes

coverage:
  precision: 2
  round: down
  range: "70...90"

  status:
    project:
      default:
        target: auto         # Compare against base commit
        threshold: 1%        # Allow 1% drop
        informational: false # Block PR if fails

    patch:
      default:
        target: 80%          # New code must have 80% coverage
        threshold: 0%        # No wiggle room
        informational: false

comment:
  layout: "reach,diff,flags,tree"
  behavior: default
  require_changes: false

ignore:
  - "tests/**"
  - "data-raw/**"
  - "inst/**"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| testthat 2.x with test_that() only | testthat 3.x with describe() blocks | testthat 3.0 (2020) | Better test organization; describe() enables hierarchical structure |
| Manual covr reports | Codecov with codecov.yml config | Codecov v4 (2023+) | PR-level coverage enforcement without custom scripts |
| r-lib/actions@v1 | r-lib/actions@v2 with RSPM | v2 release (2023) | 3-5x faster dependency installs; better caching |
| workflow_dispatch without secret inputs | workflow_dispatch with type: secret | GitHub Actions 2024 | Secure manual triggers for cassette re-recording |
| upload-artifact@v3 | upload-artifact@v4 | v4 release (2024) | Better retention controls; merged artifacts support |
| devtools::load_all() in tests | source_pipeline_files() helper | Phase 12 (2026) | Explicit dependency-order sourcing for dev/ scripts |

**Deprecated/outdated:**
- **testthat 2.x edition:** Use testthat 3.x with `Config/testthat/edition: 3` in DESCRIPTION (already configured)
- **RUnit/unittest packages:** Abandoned; testthat is ecosystem standard
- **Travis CI / AppVeyor:** GitHub Actions is now standard; r-lib/actions maintained by R-core
- **source() for pipeline files:** Use helper-pipeline.R::source_pipeline_files() instead

## Open Questions

Things that couldn't be fully resolved:

1. **EPI Suite production schemas availability**
   - What we know: Context7 shows EPI Suite has API endpoints; schema/ directory has no epi-* files
   - What's unclear: Are EPI Suite production schemas available via ct_schema()? Or is this microservice still in development?
   - Recommendation: Start E2E tests with 2 microservices (CompTox Dashboard, Cheminformatics), add EPI Suite when schemas available

2. **Optimal cassette commit strategy**
   - What we know: vcr best practices recommend committing cassettes after security review; helper-vcr.R filters API keys
   - What's unclear: Should cassettes be committed to git or generated in CI on first run? Large schema tests may produce large cassettes
   - Recommendation: Commit cassettes for integration tests (3-5 per microservice); mark fixtures/_vcr/ directory as binary in .gitattributes to avoid merge conflicts

3. **Coverage threshold enforcement timing**
   - What we know: Codecov uploads to show coverage diff; separate GHA steps enforce thresholds
   - What's unclear: Should thresholds fail before or after Codecov upload? Fail-fast vs. complete reporting?
   - Recommendation: Enforce thresholds AFTER Codecov upload so PR comments show full coverage report even on failure; use `continue-on-error: true` + explicit check

## Sources

### Primary (HIGH confidence)
- [testthat 3.3.2 official documentation](https://testthat.r-lib.org/) - Current version, describe() blocks, integration testing
- [testthat CRAN manual](https://cran.r-project.org/web/packages/testthat/testthat.pdf) - Version 3.3.2, January 11, 2026
- [R Packages (2e) - Testing basics](https://r-pkgs.org/testing-basics.html) - Official R package development guide
- [R Packages (2e) - Designing test suites](https://r-pkgs.org/testing-design.html) - Integration test patterns
- [covr official documentation](https://covr.r-lib.org/) - Coverage measurement for R packages
- [covr CRAN manual](https://cran.r-project.org/web/packages/covr/covr.pdf) - Version November 9, 2025
- [vcr getting started guide](https://docs.ropensci.org/vcr/articles/vcr.html) - Cassette organization, sensitive data filtering
- [vcr CRAN manual](https://cran.r-project.org/web/packages/vcr/vcr.pdf) - Version 2.1.0, December 5, 2025
- [r-lib/actions examples](https://github.com/r-lib/actions/tree/v2/examples) - Official R package CI patterns
- [Codecov Status Checks documentation](https://docs.codecov.com/docs/commit-status) - Threshold configuration with target/threshold settings
- [GitHub Actions workflow syntax](https://docs.github.com/en/enterprise-cloud@latest/actions/using-workflows/workflow-syntax-for-github-actions) - workflow_dispatch and official syntax
- [GitHub Actions artifacts documentation](https://docs.github.com/actions/using-workflows/storing-workflow-data-as-artifacts) - Storing workflow data as artifacts
- [devtools load_all() reference](https://devtools.r-lib.org/reference/load_all.html) - Development workflow vs source()

### Secondary (MEDIUM confidence)
- [testthat describe() nested tests blog post](https://rpahl.github.io/r-some-blog/posts/2024-10-07-nested-unit-tests-with-testthat/) - Practical nested describe() examples
- [GitHub Actions & R packages guide](https://fontikar.github.io/DIY_Rpkg_GHA/) - CI patterns for R
- [dacbd/create-issue-action](https://github.com/marketplace/actions/create-github-issue) - Auto-issue creation on failure
- [jayqi/failed-build-issue-action](https://github.com/marketplace/actions/failed-build-issue) - Alternative issue creation action
- [upload-artifact v4 documentation](https://github.com/actions/upload-artifact) - if: always() pattern for failure artifacts

### Tertiary (LOW confidence)
- WebSearch: "R package testing end-to-end integration tests" - General ecosystem patterns (not package-specific)
- WebSearch: "Codecov configuration threshold coverage fail PR check" - Configuration examples from various ecosystems

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools are official r-lib/rOpenSci packages with active maintenance and CRAN releases in 2025-2026
- Architecture: HIGH - Patterns verified from official documentation and existing codebase (helper-vcr.R, helper-pipeline.R)
- Pitfalls: MEDIUM-HIGH - Based on common GitHub issues and vcr/covr documentation warnings; EPI Suite schema availability unverified

**Research date:** 2026-01-30
**Valid until:** 2026-03-30 (60 days - testthat/covr/vcr are stable; r-lib/actions updates monthly but v2 API stable)
