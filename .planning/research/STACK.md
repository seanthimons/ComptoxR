# Technology Stack

**Project:** ComptoxR Test Infrastructure & Build Fixes (v2.1)
**Researched:** 2026-02-26

## Recommended Stack

### Core Testing Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| testthat | 3.3.2 | Unit testing framework | Current CRAN version (2026-01-11). Edition 3 required for modern test organization, snapshot testing, parallel execution. Already validated in existing infrastructure. |
| vcr | 2.1.0 | HTTP cassette recording | Current CRAN version (2025-12-05). Proven to work with 706 existing cassettes. Native integration with httr2 via webmockr. |
| withr | Latest | Temporary state management | Already in Suggests. Essential for test isolation (temp dirs, env vars, options). |

**NO CHANGES NEEDED** - These are the EXACT versions already working in the project.

### Coverage Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| covr | 3.6.5 | Code coverage calculation | Current CRAN version. Already integrated with Codecov. Supports package_coverage() and file_coverage() for granular R/ vs dev/ enforcement. |
| Codecov GHA | v4 | Coverage upload & reporting | Already configured in pipeline-tests.yml and test-coverage.yml. Threshold enforcement handled in R code (pipeline-tests.yml lines 55-85), not Codecov config, for R/dev separation. |

**NO CHANGES NEEDED** - Current setup enforces thresholds correctly (R/ >=75%, dev/ >=80%) via Rscript in CI.

### Build Validation
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| rcmdcheck | Latest via r-lib/actions | R CMD check automation | Used via r-lib/actions/check-r-package@v2 in test-coverage.yml. Detects syntax errors, documentation mismatches, license issues, non-ASCII chars. |
| devtools | Via Imports (not needed) | Local dev workflow | Currently used via :: calls (warning in TODO). Move to Suggests if keeping, or replace with direct calls to underlying packages (pkgbuild, roxygen2). |

**DECISION REQUIRED**: Fix devtools dependency warning by adding to Suggests or removing :: calls.

### VCR Cassette Management at Scale
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| fs | 1.6.6 | Cross-platform file ops | NOT currently used, but recommended for cassette bulk operations. Provides fs::dir_ls(), fs::file_delete() with better error handling and cross-platform paths than base R. |
| Custom helper | N/A | Bulk cassette operations | Extend existing tests/testthat/helper-vcr.R with fs-based helpers. Pattern-based deletion already documented (CLAUDE.md), needs implementation. |

**IMPLEMENTATION NEEDED**: Add fs to Suggests, implement delete_all_cassettes() and delete_cassettes(pattern) in helper-vcr.R.

### Test Generation Automation
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Custom generator | N/A | Metadata-based test creation | tests/testthat/tools/helper-test-generator-v2.R already exists. Uses function signature extraction + parameter type detection. Generate via tests/generate_tests_v2.R script. |
| roxygen2 | 7.3.3 | Function metadata source | Extract @param, @return, @examples from generated stubs. Already RoxygenNote: 7.3.3 in DESCRIPTION. |

**NO NEW TOOLS NEEDED** - Test generation infrastructure complete. Focus on fixing generator logic (parameter type detection, tidy flag matching).

### CI Automation & Reporting
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| GitHub Actions | N/A | Workflow automation | 11 existing workflows. pipeline-tests.yml already set up for integration testing. |
| r-lib/actions | Latest | R-specific GHA steps | setup-r@v2, setup-r-dependencies@v2, check-r-package@v2. Standard ecosystem actions, auto-updated by Dependabot. |
| cli (R pkg) | Already in Imports | Progress reporting | Already used throughout codebase. Use cli::cli_progress_bar() for cassette re-recording, cli::cli_alert_*() for status. |

**NO CHANGES NEEDED** - CI infrastructure complete. Add progress reporting to scripts via existing cli package.

### Build Error Detection
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| rcmdcheck | (see above) | Syntax/doc validation | Catches "RF" <- invalid syntax, duplicate args, roxygen @param mismatches. |
| lintr | Optional (not needed) | Static analysis | Would catch additional style issues, but TODO items are rcmdcheck errors, not style violations. Skip to avoid scope creep. |
| styler | Optional (not needed) | Code formatting | NOT needed for build fixes. Stub generator already formats code. Skip. |

**SKIP NEW TOOLS** - rcmdcheck catches all current build errors. Don't add lintr/styler unless user explicitly requests.

## Supporting Libraries

### Already in Use (Keep)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| httr2 | 1.2.1+ | HTTP client | All API wrappers. Note: TODO.md flags missing httr2 functions (resp_is_transient, resp_status_class) - verify httr2 version meets minimum or refactor retry logic. |
| jsonlite | >= 1.8.8 | JSON parsing | Schema parsing, API responses. |
| dplyr | >= 1.1.4 | Data manipulation | Test helpers, coverage scripts. |
| here | Already in Imports | Path management | Schema loading, cassette paths. |
| stringr | >= 1.5.1 | String manipulation | Pattern matching for cassette management. |
| purrr | >= 1.0.2 | Functional programming | Batch operations, test generation. |

### Consider Adding to Suggests
| Library | Rationale |
|---------|-----------|
| fs | Cassette bulk operations (706 files to manage). Better than base file.remove() for scale. |

### DO NOT ADD
| Library | Why Skip |
|---------|----------|
| patrick | Parameterized testing - test generator already handles parameter variations via metadata. Adding would duplicate functionality. |
| xpectr | Test expectation generation - custom generator (helper-test-generator-v2.R) already built and tailored to API wrapper patterns. xpectr is generic, wouldn't understand tidy flags or endpoint-specific patterns. |
| tinytest | Alternative test framework - already committed to testthat 3. |
| RUnit | Legacy framework - incompatible with vcr integration. |
| lintr | Static analysis - not needed for current build errors. Adds CI time. |
| styler | Code formatter - stub generator already formats. Not a build blocker. |
| roxytest | Inline tests - API wrappers need integration tests with real HTTP, not unit tests. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| HTTP testing | vcr 2.1.0 | httptest2 | vcr already validated with 706 cassettes. httptest2 would require rewriting all tests. |
| Coverage | covr 3.6.5 | covr + DT for HTML reports | DT adds heavy dependency for minimal gain. Codecov web UI provides better reporting. |
| File ops | fs 1.6.6 | base file.* functions | Base R works but fs provides better errors and cross-platform consistency. Low-risk addition. |
| Test generation | Custom (metadata-based) | xpectr | xpectr doesn't understand API wrapper patterns (tidy flags, DTXSID vs limit params, bulk vs single). Custom generator already built. |
| CI coverage | covr + Rscript thresholds | Codecov YAML config | Current approach enforces R/ (>=75%) and dev/ (>=80%) separately. Codecov config would apply single threshold to both. |

## Installation

### Core Dependencies (Already Satisfied)
```r
# From DESCRIPTION - no changes needed
Imports: cli, dplyr, httr2, jsonlite, purrr, stringr, here, ...
Suggests: vcr, withr, ...
```

### Recommended Addition
```r
# Add to Suggests in DESCRIPTION
Suggests:
    ...existing...,
    fs (>= 1.6.0)
```

### Local Development Setup
```r
# Install/update test dependencies
install.packages(c("testthat", "vcr", "withr", "covr", "fs"))

# Verify versions
packageVersion("testthat")  # Should be 3.3.2
packageVersion("vcr")       # Should be 2.1.0
packageVersion("covr")      # Should be 3.6.5
```

## Integration Points

### Test Generation Pipeline
```
Function stub (R/*.R)
  → roxygen2 docs (@param, @return, @examples)
  → helper-function-metadata.R (extract_function_metadata)
  → helper-test-generator-v2.R (generate test code)
  → tests/testthat/test-*.R (write file)
  → vcr (record cassettes on first run)
```

**Key integration:** Test generator reads tidy parameter from generic_request() calls to determine if function returns tibble or list. Must parse actual function body, not just signature.

### VCR Cassette Lifecycle
```
First test run (with API key)
  → vcr::use_cassette() intercepts httr2
  → HTTP request to production API
  → Response saved to tests/testthat/fixtures/*.yml
  → API key filtered via vcr_configure(filter_sensitive_data)

Subsequent runs (no API key needed)
  → vcr::use_cassette() loads fixture
  → webmockr blocks real HTTP
  → Tests run against recorded response
```

**Key integration:** helper-vcr.R configures filter_sensitive_data. Must be sourced before any vcr::use_cassette() calls (currently in tests/testthat/helper-vcr.R, loaded automatically by testthat).

### Coverage Enforcement
```
CI workflow (pipeline-tests.yml or coverage-check.yml)
  → covr::package_coverage() (R/ package code)
  → covr::file_coverage() (dev/ internal code)
  → Rscript threshold checks (R/ >= 75%, dev/ >= 80%)
  → covr::codecov() uploads to Codecov (R/ only, dev/ excluded)
```

**Key integration:** Codecov receives R/ package coverage only. Dev/ coverage enforced in CI but not uploaded (internal tooling, not shipped code).

### Build Validation
```
git push
  → GitHub Actions (test-coverage.yml or R-CMD-check.yml)
  → r-lib/actions/setup-r-dependencies (install pkg + suggests)
  → devtools::test() (run tests with vcr)
  → r-lib/actions/check-r-package (R CMD check)
  → rcmdcheck detects syntax errors, doc mismatches, warnings
  → Fail CI if errors/warnings present
```

**Key integration:** R CMD check runs AFTER tests pass. Tests use recorded cassettes (no API key needed in CI for existing cassettes).

## Version Compatibility

### Minimum R Version
- **Current:** R >= 3.5.0 (DESCRIPTION)
- **Issue:** Native pipe |> used in 7 files requires R >= 4.1.0 (TODO.md line 38)
- **Fix:** Update DESCRIPTION to `Depends: R (>= 4.1.0)`

### httr2 Version Issue
- **Problem:** Code references httr2::resp_is_transient and httr2::resp_status_class but these don't exist in installed httr2 (TODO.md line 20)
- **Solutions:**
  1. Update minimum httr2 version if functions exist in newer release
  2. Refactor retry logic to use req_retry(is_transient = ...) pattern (httr2 >= 1.0.0)
- **Verify:** Check httr2 1.2.1 changelog for these function names

### testthat Edition
- **Required:** Edition 3 (already configured via Config/testthat/edition: 3)
- **Features used:** Parallel testing, snapshot tests, modern expect_* functions
- **DO NOT downgrade** to Edition 2

## Sources

### Current Package Versions
- [testthat 3.3.2 (2026-01-11)](https://cran.r-project.org/web/packages/testthat/testthat.pdf)
- [vcr 2.1.0 (2025-12-05)](https://cran.r-project.org/web/packages/vcr/vcr.pdf)
- [covr 3.6.5 documentation](https://covr.r-lib.org/)
- [httr2 1.2.1 on CRAN](https://cran.r-project.org/package=httr2)
- [fs 1.6.6 documentation](https://fs.r-lib.org/)

### Testing Best Practices
- [HTTP testing in R - Managing cassettes](https://books.ropensci.org/http-testing/managing-cassettes.html)
- [vcr Getting Started](https://cran.r-project.org/web/packages/vcr/vignettes/vcr.html)
- [httr2 request retry documentation](https://httr2.r-lib.org/reference/req_retry.html)

### CI Integration
- [Codecov GitHub Actions integration](https://about.codecov.io/tool/github-actions/)
- [How to Generate Code Coverage Reports with GitHub Actions (2026-01-27)](https://oneuptime.com/blog/post/2026-01-27-code-coverage-reports-github-actions/view)
- [R Package CI automation - r-lib/actions](https://github.com/r-lib/actions)

### Test Generation
- [xpectr - R test generation](https://github.com/LudvigOlsen/xpectr) (evaluated but not recommended)
- [testthat documentation](https://testthat.r-lib.org/)

## Implementation Notes

### Priority 1: Fix Build Blockers (No New Dependencies)
1. Invalid syntax in chemi_arn_cats_bulk - stub generator bug
2. Duplicate endpoint args - stub generator bug
3. httr2 function references - verify version or refactor
4. Update DESCRIPTION R version to >= 4.1.0 for native pipe

**Tools:** rcmdcheck (already in CI), stub generator fixes (dev/endpoint_eval/)

### Priority 2: Fix Test Infrastructure (Minimal New Dependencies)
1. Add fs to Suggests for cassette management
2. Implement delete_all_cassettes() and delete_cassettes(pattern) in helper-vcr.R
3. Fix test generator parameter type detection (helper-test-generator-v2.R)
4. Fix test generator tidy flag matching (read actual function body)

**Tools:** fs (add to Suggests), custom test generator (already exists)

### Priority 3: Cassette Re-recording (Use Existing Tools)
1. Run delete_all_cassettes() to nuke 706 fixtures
2. Set ctx_api_key env var
3. Run devtools::test() to re-record from production
4. Run devtools::test() again to verify cassettes work
5. Use check_cassette_safety() to verify no exposed keys
6. Commit cassettes

**Tools:** vcr (already installed), custom helpers (implement in helper-vcr.R)

### Priority 4: CI Enhancements (No New Dependencies)
1. Add cli progress bars to cassette re-recording script
2. Add workflow dispatch input for "re-record cassettes" flag (already in pipeline-tests.yml line 9)
3. Improve coverage reporting with file-level breakdown

**Tools:** cli (already in Imports), GitHub Actions (already configured)

## What NOT to Add

### Avoided: Test Generation Tools
- **xpectr** - Generic test generator doesn't understand API wrapper patterns (tidy flags, DTXSID vs other params, bulk vs single requests). Custom generator (helper-test-generator-v2.R) already tailored to ComptoxR patterns.
- **patrick** - Parameterized testing adds complexity. Custom generator handles parameter variations via metadata extraction.
- **roxytest** - Inline tests inappropriate for API wrappers requiring live HTTP (or cassettes).

### Avoided: Static Analysis Tools
- **lintr** - Build errors are syntax/logic issues, not style violations. Adding lintr increases CI time without solving current blockers.
- **styler** - Stub generator already formats code. Not needed for build fixes.

### Avoided: Alternative Testing Frameworks
- **httptest2** - Would require rewriting 706 VCR cassettes. vcr working fine.
- **tinytest** - Already committed to testthat 3. No migration path.
- **RUnit** - Legacy framework, incompatible with vcr.

### Avoided: Heavy Dependencies
- **DT** - HTML coverage reports add 10+ dependency packages. Codecov web UI provides better reporting.
- **shiny** - No need for interactive test runners. CI-first workflow.

## Confidence Assessment

| Area | Confidence | Reasoning |
|------|------------|-----------|
| Core stack | HIGH | testthat 3.3.2, vcr 2.1.0, covr 3.6.5 verified via CRAN. Already working in project (706 cassettes, 11 CI workflows). |
| fs addition | MEDIUM | Version 1.6.6 verified via CRAN. Standard r-lib package, low risk. Not critical path - base R file ops work, fs just cleaner. |
| httr2 version issue | LOW | resp_is_transient and resp_status_class referenced but not found. Need to check httr2 1.2.1 docs to verify if functions exist or if retry logic needs refactor. |
| Test generator fixes | HIGH | helper-test-generator-v2.R exists and documented. Issues are logic bugs (wrong param types, tidy flag mismatch), not missing tools. |
| Cassette management | MEDIUM | Pattern exists in docs (CLAUDE.md shows delete_all_cassettes, delete_cassettes), but not implemented in helper-vcr.R. Implementation straightforward with fs. |
| CI integration | HIGH | 11 existing workflows, pipeline-tests.yml already enforces R/dev coverage separately. No new tools needed, just script improvements. |

## Open Questions

1. **httr2 minimum version:** Does httr2 1.2.1 include resp_is_transient and resp_status_class, or were these removed? If removed, what's the modern equivalent for req_retry(is_transient = ...)?

2. **devtools dependency:** Keep in Suggests or remove :: calls? Used for document(), test(), check() but these can be called via roxygen2::, testthat::, rcmdcheck:: directly.

3. **Test generation scope:** Generate tests for ALL 250+ exported functions, or only new stubs? README.md suggests metadata-based generator (v2) exists but TODO.md shows 834+ test failures from auto-generated tests - indicates generator needs fixes before mass regeneration.

4. **Cassette re-recording strategy:** Delete all 706 and re-record, or delete only the 673 untracked (per TODO.md) that have wrong parameter values? Full re-record safer but requires API key + rate limit management.
