# Project Research Summary

**Project:** ComptoxR Test Infrastructure & Build Fixes (v2.1)
**Domain:** R package test infrastructure for API wrappers
**Researched:** 2026-02-26
**Confidence:** HIGH

## Executive Summary

ComptoxR is an R package providing EPA CompTox API wrappers with 370+ functions. The project has mature stub generation infrastructure (v1.9) producing clean API wrappers, but test generation is broken. The current test generator produces 834+ failing tests because it blindly assumes all parameters are DTXSIDs and doesn't read the actual `tidy` flag from function implementations, causing wrong parameter types and incorrect return type assertions. Additionally, 673 VCR cassettes were recorded with these broken tests, capturing malformed API requests.

The recommended approach is to fix the test generator metadata extraction first (read actual parameter types and tidy flags from stubs), then delete all bad cassettes, regenerate tests with correct parameters, and finally re-record clean cassettes in batches to avoid EPA API rate limits. The existing infrastructure (testthat 3.3.2, vcr 2.1.0, covr 3.6.5) is solid and requires no changes. The automation pipeline should follow a detection-then-generation pattern: detect which functions lack tests, generate only for those gaps, commit both stubs and tests together, then cassettes record automatically on first CI run.

Key risks include API rate limiting during mass cassette re-recording (batch 20-50 at a time with delays), API keys leaking into cassettes (already configured to filter but needs verification), and coverage threshold failures from defensive code in generated stubs (exclude auto-generated files or use lower thresholds). The stub generator has syntax bugs producing invalid R code that must be fixed before generating any tests.

## Key Findings

### Recommended Stack

The current stack is production-ready and requires minimal changes. All core dependencies (testthat 3.3.2, vcr 2.1.0, covr 3.6.5, httr2 1.2.1+) are latest CRAN versions already validated with 706 existing cassettes and 11 CI workflows. The test generation infrastructure exists (`helper-test-generator-v2.R`, `helper-function-metadata.R`) but needs logic fixes, not new tools.

**Core technologies:**
- testthat 3.3.2: Unit testing framework — Current version, Edition 3 required for parallel execution and snapshots. Already working.
- vcr 2.1.0: HTTP cassette recording — Proven with 706 cassettes. Native httr2 integration. No changes needed.
- covr 3.6.5: Code coverage calculation — Already integrated with Codecov. Enforces R/ >=75%, dev/ >=80% separately via Rscript in CI.
- Custom test generator: Metadata-based test creation — Exists at `tests/testthat/tools/helper-test-generator-v2.R`. Needs parameter type detection fixes.

**Recommended addition:**
- fs 1.6.6: Cross-platform file operations — For bulk cassette management (706 files). Better than base R `file.remove()` at scale. Add to Suggests.

**Do NOT add:**
- xpectr, patrick (test generation tools — custom generator already tailored to API patterns)
- lintr, styler (static analysis — not needed for current build errors)
- httptest2 (would require rewriting 706 cassettes)

### Expected Features

API wrapper packages must have comprehensive testthat coverage (75%+ for rOpenSci), VCR cassette recording (standard practice), R CMD check passing (CRAN requirement), and CI/CD on multiple platforms. Tests must handle batch operations, pagination edge cases, error responses, and authentication without exposing credentials.

**Must have (table stakes):**
- Comprehensive testthat suite — Required for CRAN/rOpenSci submission
- VCR cassette recording — Standard for API testing, prevents flaky network tests
- R CMD check passing — CRAN submission requirement (Windows/macOS/Linux)
- Security-filtered cassettes — Prevent accidental credential leaks
- Parameterized tests for batch operations — Essential for API wrappers with batching
- Error response handling tests — APIs fail; packages must handle gracefully

**Should have (competitive):**
- Automated test generation from schemas — Scales to 100+ endpoints efficiently (reduces boilerplate by 80%+)
- Metadata-driven test templates — Ensures consistency across function families
- Cassette lifecycle automation — Reduces maintenance burden with automated re-recording
- Coverage thresholds in CI — Enforces quality standards automatically (already implemented: R/ >=75%, dev/ >=80%)
- Integration tests for pipeline — Catches schema→stub→test breaks early

**Defer (v2+):**
- Performance benchmarking tests — Not blocking; add after pagination stabilizes
- Contract testing for API versioning — Nice-to-have; current schema diffing handles breaking changes
- Test data factories — Hardcoded DTXSIDs work for now; optimize if scaling to 1000+ tests
- Snapshot testing — testthat 3e feature; current list assertions work fine

### Architecture Approach

ComptoxR's test infrastructure requires integrating three workflows: stub generation → test generation → VCR cassette recording. The architecture uses a detection-then-generation pattern to avoid overwriting manual tests. After stubs are generated, detect functions lacking tests, generate test files for gaps, commit together, then cassettes record on first CI run with API key. Test generator reads function metadata directly from generated stubs to produce correct parameter types and return type assertions.

**Major components:**
1. Test Generator v2 (`helper-test-generator-v2.R`) — Extracts metadata from stubs, generates 4 test types (basic/example/batch/error). Requires fixes: read `tidy` flag from function body, detect parameter types from names/schemas, not assumptions.
2. Test Gap Detector (NEW: `dev/detect_test_gaps.R`) — Scans R/ for functions without corresponding test files. Outputs list to GITHUB_OUTPUT for CI automation.
3. Batch Test Orchestrator (NEW: `dev/generate_tests.R`) — Wrapper around test-generator-v2. Generates tests for multiple functions from gap list. Reports success/skip counts.
4. Cassette Cleanup Script (NEW: `dev/cleanup_cassettes.R`) — Deletes cassettes by pattern or function name. Enables targeted re-recording after fixing tests.
5. VCR Configuration (`helper-vcr.R`) — Filters API keys from cassettes. Already configured correctly but needs verification before mass re-recording.

**Key patterns:**
- Detection-then-generation: Don't generate blindly; check what's missing first to avoid overwriting manual tests
- Metadata-driven generation: Read actual parameter types from stubs, not assumptions
- Cassette-per-test-variant: Each test (single/batch/error/example) gets unique cassette for isolated re-recording
- Lifecycle protection: Skip functions marked `@lifecycle stable` to protect production code
- Two-phase cassette recording: Initial recording may fail (expected); fix tests, delete cassettes, re-record clean

### Critical Pitfalls

**Top 5 pitfalls from research:**

1. **Test generator blindly uses DTXSIDs for all parameters** — Produces `limit = "DTXSID7020182"`, `search_type = "DTXSID7020182"` causing 834 test failures. Fix by extracting actual parameter types from function signatures or schemas, mapping parameter names to appropriate test values (limit → integer, search_type → enum).

2. **tidy=FALSE/tibble assertion mismatch** — 122 functions return lists (`tidy=FALSE`) but tests assert `expect_s3_class(result, "tbl_df")`. Fix by parsing stub source to extract `tidy` parameter value from `generic_request()` calls, generating assertions that match actual return type.

3. **VCR cassettes recorded with wrong parameters** — 673 untracked cassettes contain API error responses from malformed requests. Prevention: NEVER commit cassettes from first test run without validation. Review for HTTP 4xx/5xx codes. Use `check_cassette_safety()` helper. Delete and re-record with correct params.

4. **Mass API re-recording without rate limit awareness** — Re-recording 300+ cassettes triggers EPA API rate limiting, causing partial cassette sets and 429 errors mid-batch. Batch re-recording: 20-50 cassettes at a time with `Sys.sleep(0.5)` delays. Use staging endpoints if available. Never run full re-recording in CI.

5. **API keys leaked in VCR cassettes** — If `vcr_configure(filter_sensitive_data)` is misconfigured, cassettes contain plaintext keys. Configure filtering in `helper-vcr.R` before any tests run. Filter both variable name variations. Run `check_cassette_safety()` before committing. Store keys in `.Renviron`, never hardcode.

**Other critical issues:**
- **Invalid stub syntax** — Stub generator produces `"RF" <- model = "RF"` or duplicate `endpoint` args, killing R CMD check. Fix template escaping, deduplicate parameters during rendering.
- **Pipeline tests reference dev/ files** — 6 `test-pipeline-*.R` files fail during R CMD check because `dev/` excluded from built package. Move utilities to `tests/testthat/helper-*.R` or skip if `dev/` missing.
- **Coverage threshold failures** — Auto-generated stubs include defensive code never executed with VCR mocks, causing coverage to fail even with full functional tests. Exclude generated files or use lower thresholds (50-60% for stubs vs 75%+ for core).

## Implications for Roadmap

Based on research, suggested phase structure prioritizes fixing build blockers, cleaning bad infrastructure, then automating workflows. The test generator bugs must be fixed before any cassette re-recording, and stubs must be syntactically valid before tests are generated.

### Phase 1: Fix Build Blockers & Test Generator Core
**Rationale:** Can't generate clean tests until generator reads actual function metadata. Invalid stub syntax prevents package from building. These are zero-functionality blockers.

**Delivers:**
- Stub generator producing valid R syntax (no reserved word collisions, no duplicate args)
- Test generator reading `tidy` flag from function bodies
- Test generator mapping parameter names to correct test value types
- R CMD check passing with 0 errors

**Addresses:**
- Table stakes: R CMD check passing (CRAN requirement)
- Pitfall 1: Blind DTXSID test generation
- Pitfall 2: tidy/tibble assertion mismatch
- Pitfall 8: Invalid stub syntax

**Avoids:**
- Generating 834+ broken tests that need to be thrown away
- Recording cassettes with wrong parameters that must be deleted
- Build failures blocking all development

**Technical work:**
- Fix stub template escaping for R reserved words
- Add parameter deduplication to stub rendering
- Update `helper-function-metadata.R` to extract `tidy` value from `generic_request()` calls
- Update `helper-test-generator-v2.R` to map parameter names to test value types
- Add R CMD check validation to stub generation CI

### Phase 2: Clean VCR Cassettes & Infrastructure
**Rationale:** Can't commit bad cassettes to git. Must verify API key filtering works. Need bulk cleanup tools for 673 untracked cassettes. This phase depends on Phase 1 test generator fixes.

**Delivers:**
- Cassette cleanup script (`dev/cleanup_cassettes.R`) for pattern-based deletion
- Verified VCR filtering configuration (no API keys in cassettes)
- Clean cassette set for critical functions (delete bad ones, regenerate tests, re-record in batches)
- Documentation for cassette re-recording workflow

**Addresses:**
- Table stakes: Security-filtered cassettes (prevent credential leaks)
- Pitfall 3: VCR cassettes recorded with wrong parameters
- Pitfall 4: Mass API re-recording without rate limits
- Pitfall 6: API keys leaked in cassettes

**Avoids:**
- API rate limiting (batch 20-50 cassettes at a time with delays)
- Exposing credentials to public GitHub repo
- Committing error responses as valid test fixtures

**Technical work:**
- Add fs to Suggests in DESCRIPTION
- Implement `delete_all_cassettes()` and `delete_cassettes(pattern)` in `helper-vcr.R`
- Verify `vcr_configure(filter_sensitive_data)` catches all API key variations
- Run `check_cassette_safety()` on all 706 existing cassettes
- Delete 673 untracked cassettes with bad parameters
- Regenerate tests for high-priority functions (hazard, exposure, chemical domains)
- Re-record cassettes in batches (20-50 at a time with delays)
- Document batched re-recording workflow in CLAUDE.md

### Phase 3: Automate Test Generation Pipeline
**Rationale:** Manual test generation doesn't scale to 370+ functions. Need CI automation to detect stub-test gaps and generate missing tests automatically. This phase depends on Phase 1 (test generator working) and Phase 2 (cassette management tools).

**Delivers:**
- Test gap detection script (`dev/detect_test_gaps.R`)
- Batch test orchestrator (`dev/generate_tests.R`)
- CI workflow for automated test generation after stub creation
- Gap reporting in CI summary and PR comments

**Addresses:**
- Differentiator: Automated test generation from schemas
- Differentiator: Metadata-driven test templates
- Integration tests for schema→stub→test pipeline

**Avoids:**
- Anti-pattern: Generating tests before stubs are stable
- Anti-pattern: Overwriting manually written tests
- Anti-pattern: No test-to-function traceability

**Technical work:**
- Create `dev/detect_test_gaps.R` (scan R/ vs tests/, output gap list)
- Create `dev/generate_tests.R` (wrapper around test-generator-v2)
- Create `.github/workflows/generate-tests.yml` (automate detection → generation → commit)
- Add lifecycle protection to test generator (skip `@lifecycle stable` functions)
- Add GITHUB_OUTPUT to stub generator (trigger test generation)
- Implement gap reporting in CI (summary + PR comments)

### Phase 4: Coverage Enforcement & CI Hardening
**Rationale:** Coverage thresholds prevent regression but fail with auto-generated defensive code. Need to exclude generated stubs from strict thresholds or document lower expectations. This phase polishes CI after core functionality works.

**Delivers:**
- Coverage configuration excluding auto-generated stubs (or lower thresholds)
- CI enhancements: progress bars for cassette operations, better error reporting
- Documentation for coverage expectations (R/ >=75%, dev/ >=80%, stubs >=50%)
- Troubleshooting guide for common test failures

**Addresses:**
- Table stakes: Coverage reporting integration (already implemented, needs tuning)
- Differentiator: Coverage thresholds in CI (already at 75%+ but needs stub handling)
- Pitfall 7: Coverage thresholds fail due to untestable generated code

**Avoids:**
- False negatives (good code failing coverage due to defensive branches)
- Developer frustration from unrealistic coverage expectations on generated code

**Technical work:**
- Configure `covr::package_coverage(exclude_pattern = ...)` for auto-generated files
- Add cli progress bars to cassette re-recording scripts
- Document coverage philosophy in CONTRIBUTING.md
- Create troubleshooting guide for test failures (parameter type errors, tidy mismatches, rate limits)
- Add workflow dispatch input for re-recording cassettes flag

### Phase Ordering Rationale

**Why Phase 1 first:**
- Build blockers prevent all other work. Can't generate tests from broken stubs.
- Test generator bugs cause 834 failures. Fixing now prevents wasted cassette recording.
- Invalid syntax in stubs blocks package development and R CMD check.

**Why Phase 2 before Phase 3:**
- Automated test generation is useless if it produces tests requiring bad cassettes.
- Need cassette cleanup tools to fix mistakes from Phase 1 test regeneration.
- Must verify API key filtering before CI starts recording cassettes automatically.

**Why Phase 3 before Phase 4:**
- Can't enforce coverage thresholds until test generation is automated and working.
- Gap detection informs coverage reporting (which functions lack tests).
- CI automation enables faster iteration for Phase 4 refinements.

**Dependency chain:**
```
Phase 1 (Fix generators) → Phase 2 (Clean cassettes) → Phase 3 (Automate) → Phase 4 (Polish CI)
```

**Parallel opportunities:**
- Phase 2 cassette cleanup can start early if manual test generation is used
- Phase 4 documentation can be written during Phase 2-3 implementation

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 2:** EPA API rate limit policies — Undocumented; need to discover through testing. Check for `X-RateLimit-Remaining` headers in responses.
- **Phase 2:** httr2 version compatibility — Code references `resp_is_transient()` and `resp_status_class()` but these may not exist in httr2 1.2.1. Verify or refactor retry logic.

**Phases with standard patterns (skip research-phase):**
- **Phase 1:** Test generator fixes — Well-documented R metaprogramming patterns. Clear implementation path.
- **Phase 3:** CI automation — GitHub Actions workflows follow established patterns. `r-lib/actions` provides templates.
- **Phase 4:** Coverage configuration — covr package has extensive documentation for exclusion patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | testthat 3.3.2, vcr 2.1.0, covr 3.6.5 verified via CRAN. Already working in project (706 cassettes, 11 CI workflows). No new major dependencies needed. |
| Features | HIGH | rOpenSci standards (75% coverage, testthat, VCR) are well-documented requirements. API wrapper patterns established in ecosystem (httr2, vcr, testthat integration). |
| Architecture | HIGH | Detection-then-generation pattern proven in similar projects. Test generator exists and documented. Missing components are straightforward (gap detector, orchestrator, cleanup script). |
| Pitfalls | HIGH | All pitfalls have concrete evidence in TODO.md (834 test failures, 673 bad cassettes, syntax errors). Recovery strategies tested in similar R packages. |

**Overall confidence:** HIGH

### Gaps to Address

**httr2 minimum version:**
Code references `httr2::resp_is_transient()` and `httr2::resp_status_class()` but these may not exist in httr2 1.2.1. Need to verify httr2 changelog or refactor to use `req_retry(is_transient = ...)` pattern. Discovery during Phase 1.

**EPA API rate limits:**
Undocumented in official EPA API docs. Need empirical testing to determine safe request rates. Start with 20-50 requests per batch with 0.5s delays, adjust based on observed 429 responses. Discovery during Phase 2 cassette re-recording.

**devtools dependency:**
TODO.md flags devtools in Imports but only used via `::` calls (`devtools::document()`, `devtools::test()`). Decision needed: add to Suggests or replace with direct calls to underlying packages (roxygen2, testthat, rcmdcheck). Not blocking; address during Phase 1 or 4.

**Test coverage for generated stubs:**
Current approach enforces 75% coverage universally. Auto-generated stubs include defensive code never executed with VCR mocks. Need to determine realistic threshold (50-60%) or exclusion pattern. Discovery during Phase 4.

## Sources

### Primary (HIGH confidence)
- [testthat 3.3.2 (2026-01-11)](https://cran.r-project.org/web/packages/testthat/testthat.pdf) — Core testing framework, version verification
- [vcr 2.1.0 (2025-12-05)](https://cran.r-project.org/web/packages/vcr/vcr.pdf) — HTTP cassette recording, version verification
- [covr 3.6.5 documentation](https://covr.r-lib.org/) — Code coverage calculation
- [HTTP testing in R - Managing cassettes](https://books.ropensci.org/http-testing/managing-cassettes.html) — rOpenSci VCR best practices
- [HTTP testing in R - Security with vcr](https://books.ropensci.org/http-testing/vcr-security.html) — Credential filtering patterns
- [rOpenSci Testing Standards](https://devguide.ropensci.org/pkg_building.html) — 75% coverage threshold, testthat requirement
- [CRAN Submission Checklist](https://cran.r-project.org/web/packages/submission_checklist.html) — R CMD check requirements
- TODO.md (project file) — 834 test failures, 673 bad cassettes, syntax errors documented
- .planning/PROJECT.md (project file) — v1.0-v1.9 stub generation history, milestone context

### Secondary (MEDIUM confidence)
- [R Packages (2e) - Testing basics](https://r-pkgs.org/testing-basics.html) — Test organization patterns
- [R Packages (2e) - Designing Your Test Suite](https://r-pkgs.org/testing-design.html) — Hermetic tests, file system management
- [httr2 - Wrapping APIs](https://httr2.r-lib.org/articles/wrapping-apis.html) — API wrapper design patterns
- [httr2 request retry documentation](https://httr2.r-lib.org/reference/req_retry.html) — Retry logic implementation
- [patrick Package](https://github.com/google/patrick) — Parameterized testing (evaluated but not recommended)
- [xpectr Package](https://github.com/LudvigOlsen/xpectr) — Test generation (evaluated but not recommended)

### Tertiary (LOW confidence)
- [API Rate Limiting 2026 Guide](https://www.levo.ai/resources/blogs/api-rate-limiting-guide-2026) — General rate limit patterns (EPA specifics undocumented)
- [GitHub - r-lib/covr](https://github.com/r-lib/covr) — Coverage exclusion patterns (needs testing for auto-generated code)

---
*Research completed: 2026-02-26*
*Ready for roadmap: yes*
