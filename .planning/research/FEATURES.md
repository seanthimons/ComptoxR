# Feature Landscape

**Domain:** R package test infrastructure for API wrappers
**Researched:** 2026-02-26

## Table Stakes

Features users expect. Missing = package feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Comprehensive testthat suite | Required for CRAN, rOpenSci review | Medium | 75%+ coverage threshold for rOpenSci; covers major functionality + error cases |
| VCR cassette recording | Standard for API testing in R | Low | First run records from production; subsequent runs replay; prevents flaky network tests |
| R CMD check passing | CRAN submission requirement | Low | Must pass on Windows/macOS/Linux with `--as-cran` flag |
| CI/CD on multiple platforms | Expected for professional packages | Medium | GitHub Actions standard; test on R-release + R-devel; Windows/macOS/Linux |
| Coverage reporting integration | Standard visibility practice | Low | Codecov or Coveralls; automatic PR comments showing coverage delta |
| Security-filtered cassettes | Prevent accidental credential leaks | Medium | vcr 2.0.0+ auto-filters Authorization header; manual filtering for other secrets |
| Test fixtures organized by function | Makes test suite maintainable | Low | One cassette per function + test scenario; clear naming convention |
| Skip-on-CRAN guards for API calls | Prevent CRAN check failures | Low | `testthat::skip_on_cran()` for live API tests; cassette tests run everywhere |
| Documentation of test strategy | Helps contributors understand approach | Low | Explain cassette recording, how to re-record, CI behavior |
| Parameterized tests for batch operations | Essential for API wrappers with batching | Medium | Use patrick package; test single/batch/empty inputs systematically |
| Pagination-specific tests | Critical for endpoints returning large datasets | Medium | Test first page, last page, empty results, page size limits |
| Error response handling tests | APIs fail; packages must handle gracefully | Medium | Test 4xx/5xx responses, timeouts, malformed responses, rate limits |
| Authentication fixture setup | Enable testing without real credentials | High | Mock auth in tests; use fake keys that vcr accepts; document token setup |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Automated test generation from schemas | Scales to 100+ endpoints efficiently | High | Generate test skeletons from OpenAPI specs; reduces manual boilerplate by 80%+ |
| Metadata-driven test templates | Ensures consistency across function families | High | Single template generates correct tests for different parameter types (DTXSID vs formula vs mass) |
| Cassette lifecycle automation | Reduces maintenance burden | Medium | CI workflow to detect stale cassettes; automated re-recording on schema changes |
| Integration tests (schema→stub→test→execute) | Catches pipeline breaks early | Medium | E2E tests verify entire generation pipeline; not just unit-level components |
| Coverage thresholds in CI | Enforces quality standards automatically | Low | Fail builds below 75% (R/) or 80% (dev/); prevents regression |
| Snapshot testing for complex responses | Catches unintended API changes | Medium | Use testthat 3e snapshots for nested list structures; easier than manual assertions |
| Test data factories | Generate realistic test fixtures programmatically | Medium | Build valid DTXSID/CAS/SMILES sets for testing; avoid hardcoded values |
| Cassette sanitization checker | Pre-commit validation of sensitive data removal | Medium | Helper function scans cassettes for common secret patterns before git add |
| Local dev script for test regeneration | Speeds up development iteration | Low | `dev/regenerate_tests.R` re-runs generator without CI overhead |
| Test coverage heat map by module | Visualizes weak spots in test suite | Medium | Coverage breakdown by API domain (hazard vs exposure vs chemical) |
| Performance benchmarking tests | Tracks pagination/batching efficiency | High | Monitor request count, memory usage, timing for large batch operations |
| Contract testing for API versioning | Detects breaking API changes | High | Compare recorded cassettes to current API responses; alert on schema drift |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| 100% coverage obsession | Diminishing returns; forces awkward test gymnastics | Target 75-85% with focus on critical paths; skip trivial getters/setters |
| Tests that hit live APIs in CI | Flaky; rate-limited; credential management nightmare | Use VCR cassettes; schedule weekly "live API validation" job separately |
| Hardcoded API keys in test fixtures | Security leak; will get committed to git | Always use environment variables + vcr filtering; fake keys in cassettes |
| One giant test file per module | Unmaintainable; slow to run; hard to debug | One file per function (test-ct_hazard.R); organize by API endpoint |
| Testing internal helper functions extensively | Brittle; couples tests to implementation | Test through public API; internal functions covered transitively |
| Complex mocking frameworks for API responses | Fragile; duplicates vcr functionality | Use vcr/webmockr for HTTP; only mock auth/file I/O if necessary |
| Re-recording cassettes on every CI run | Defeats purpose of cassettes; hits rate limits | Record once; commit to git; re-record only when API/params change |
| Tests that write to project directories | Fails in read-only CI environments; pollutes repo | Write to session temp dir only; clean up with `withr::local_tempdir()` |
| Snapshot tests for unstable API fields | Flaky; breaks on minor API tweaks (timestamps) | Extract stable fields for assertions; ignore ephemeral data |
| Generating tests for empty POST endpoints | No-op functions; nothing to test | Skip during generation; document why in skipped endpoints log |
| Testing error messages verbatim | Brittle; breaks when error text tweaks | Use `expect_error(class = "custom_error")` or pattern matching |
| Committing `.Rbuildignore`'d cassettes | Breaks CRAN build tests | If cassettes excluded from build, also exclude from git; otherwise include both |

## Feature Dependencies

```
VCR cassette recording
  → Security filtering (must filter before first commit)
  → Test fixtures organized (cassette per function)

Automated test generation
  → Function metadata extraction (needs introspection)
  → Template engine (generates test code from schema)
  → Schema parsing (OpenAPI/Swagger)

Coverage thresholds in CI
  → Coverage reporting integration (Codecov setup)
  → CI/CD platform (GitHub Actions)

Parameterized tests
  → patrick package
  → Test data factories (generate parameter combinations)

Cassette lifecycle automation
  → Schema diffing (detect API changes)
  → CI workflow triggers (scheduled or manual)
  → VCR re-recording (regenerate cassettes)

Integration tests
  → All pipeline components (schema parser, stub generator, test generator)
  → VCR cassettes (for execute step)
```

## MVP Recommendation

Prioritize (ComptoxR current state: has basic infrastructure, needs hardening):

1. **Security-filtered cassettes** (CRITICAL) - 324 test files already exist; audit all for leaked credentials
2. **Metadata-driven test templates** (HIGH) - Fix test generator v2 to respect parameter types (tidy flags, string vs array)
3. **Automated test generation from schemas** (HIGH) - Rebuild generator to produce correct tests for all 35 exported functions
4. **Cassette lifecycle automation** (MEDIUM) - Weekly CI job to detect stale cassettes; helper script to bulk re-record
5. **Coverage thresholds in CI** (MEDIUM) - Already at 95%+ coverage; enforce 75% floor to prevent regression
6. **Integration tests** (MEDIUM) - Add E2E tests for schema→stub→test pipeline (v1.8 added endpoint eval tests, needs test generator coverage)

Defer:

- **Performance benchmarking tests**: Not blocking; add after pagination stabilizes
- **Contract testing for API versioning**: Nice-to-have; current schema diffing (v1.9) handles breaking changes
- **Test data factories**: Current approach (hardcoded DTXSIDs in fixtures) works; optimize if test generation scales to 1000+ tests
- **Snapshot testing for complex responses**: testthat 3e feature; ComptoxR uses list assertions effectively
- **Test coverage heat map by module**: Codecov provides this; no need for custom solution

## Dependencies on Existing ComptoxR Features

| New Feature | Depends On (Already Built) |
|-------------|---------------------------|
| Metadata-driven test templates | `helper-function-metadata.R` (introspection system) |
| Automated test generation | Stub generation pipeline (v1.0-v1.6), schema parsing |
| Security-filtered cassettes | VCR setup (existing), `helper-vcr.R` functions |
| Cassette lifecycle automation | Schema diffing (v1.9), `delete_all_cassettes()` helper |
| Coverage thresholds in CI | Existing CI workflows (test-coverage.yml, coverage-check.yml) |
| Integration tests | v1.8 endpoint eval test infrastructure |

## Complexity Notes

**Low complexity** (1-2 days):
- Coverage thresholds in CI (configuration change)
- Skip-on-CRAN guards (one-line addition)
- Test fixtures organized (file renaming/restructuring)
- Local dev script for test regeneration (wrapper script)

**Medium complexity** (3-7 days):
- VCR cassette recording (initial setup done; refinement needed)
- Security-filtered cassettes (audit + configuration)
- Parameterized tests (requires patrick integration + template updates)
- Pagination-specific tests (needs test data for edge cases)
- Cassette lifecycle automation (CI workflow + helper functions)
- Cassette sanitization checker (pattern matching + pre-commit hook)
- Snapshot testing (new testing paradigm; learning curve)

**High complexity** (1-3 weeks):
- Automated test generation from schemas (core v2.1 milestone work)
- Metadata-driven test templates (requires introspection system + template engine)
- Authentication fixture setup (mocking strategy + vcr integration)
- Integration tests (E2E pipeline; many moving parts)
- Performance benchmarking tests (instrumentation + baseline establishment)
- Contract testing for API versioning (requires API response comparison framework)

## Sources

**rOpenSci Standards:**
- [rOpenSci Testing Standards](https://devguide.ropensci.org/pkg_building.html) - 75% coverage threshold, testthat requirement
- [rOpenSci CI Best Practices](https://devguide.ropensci.org/pkg_ci.html) - Codecov integration, multi-platform testing
- [HTTP Testing Book - Managing Cassettes](https://books.ropensci.org/http-testing/managing-cassettes.html) - VCR lifecycle best practices
- [HTTP Testing Book - Security with vcr](https://books.ropensci.org/http-testing/vcr-security.html) - Credential filtering patterns
- [HTTP Testing Book - vcr Package](https://books.ropensci.org/http-testing/vcr.html) - Record/replay strategies
- [API Package Best Practices](https://docs.ropensci.org/crul/articles/best-practices-api-packages.html) - API wrapper design patterns

**CRAN Requirements:**
- [CRAN Submission Checklist](https://cran.r-project.org/web/packages/submission_checklist.html) - R CMD check requirements
- [R CMD check Documentation](https://r-pkgs.org/R-CMD-check.html) - Check requirements and timing constraints

**Testing Tools and Patterns:**
- [testthat Documentation](https://testthat.r-lib.org/) - Core testing framework
- [testthat 3.3.2 Manual](https://cran.r-project.org/web/packages/testthat/testthat.pdf) - Snapshot testing, expectations
- [R Packages - Testing Basics](https://r-pkgs.org/testing-basics.html) - File system management, coverage goals
- [R Packages - Designing Your Test Suite](https://r-pkgs.org/testing-design.html) - Test organization, hermetic tests
- [patrick Package](https://github.com/google/patrick) - Parameterized testing for R
- [xpectr Package](https://github.com/LudvigOlsen/xpectr) - Test expectation generation
- [Introduction to Snapshot Testing in R](https://indrajeetpatil.github.io/intro-to-snapshot-testing/) - Snapshot testing patterns

**Coverage and CI:**
- [covr Package](https://covr.r-lib.org/) - Test coverage reporting
- [Codecov Documentation](https://docs.codecov.com/docs) - Coverage thresholds and configuration
- [rworkflows Package](https://github.com/neurogenomics/rworkflows) - Automated CI workflows for R packages

**API Wrapper Examples:**
- [httr2 - Wrapping APIs](https://httr2.r-lib.org/articles/wrapping-apis.html) - API wrapper design patterns
- [httptest2 Package](https://enpiar.com/httptest2/) - HTTP testing for httr2
- [googledrive Package](https://github.com/tidyverse/googledrive) - gargle authentication approach
- [gh Package](https://github.com/r-lib/gh) - Minimalistic API client

**VCR Documentation:**
- [vcr Package CRAN](https://cran.r-project.org/web/packages/vcr/index.html) - Official CRAN package
- [vcr Getting Started](https://docs.ropensci.org/vcr/articles/vcr.html) - Basic usage patterns
- [vcr GitHub Repository](https://github.com/ropensci/vcr) - Source and issues

**Testing Best Practices:**
- [Automated Testing with testthat in Practice](https://www.r-bloggers.com/2019/11/automated-testing-with-testthat-in-practice/) - Real-world patterns
- [API Pagination in R and httr2](https://community.qualtrics.com/qualtrics-api-13/api-pagination-in-r-and-httr2-29516) - Pagination testing
- [Guide to Autotest Tool](https://www.devzery.com/post/guide-to-autotest-tool-automating-r-package-testing) - Automated edge case detection

**Coverage Philosophy:**
- [Why 100% Test Coverage is Not Optimal](https://medium.com/@dolanmiu/why-have-100-test-coverage-89026f6135ce) - Diminishing returns argument
- [Should You Aim for 100 Percent Test Coverage?](https://blog.ndepend.com/aim-100-percent-test-coverage/) - Practical thresholds
- [Test Coverage: n% Does Not Really Matter](https://stouf.medium.com/test-coverage-n-does-not-really-matter-d069bf9ccd57) - Quality over quantity

**Anti-Patterns:**
- [Software Testing Anti-Patterns](https://testrigor.com/blog/software-testing-anti-patterns-and-ways-to-avoid-them/) - Common mistakes
- [Unit Testing Anti-Patterns Full List](https://dzone.com/articles/unit-testing-anti-patterns-full-list) - Comprehensive catalog
