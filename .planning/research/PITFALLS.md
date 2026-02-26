# Pitfalls Research

**Domain:** R API Wrapper Package Test Infrastructure
**Researched:** 2026-02-26
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Test Generator Blindly Uses DTXSIDs for All First Parameters

**What goes wrong:**
Test generator assumes every function's first parameter accepts DTXSIDs, resulting in tests that pass `limit = "DTXSID7020182"`, `search_type = "DTXSID7020182"`, or `page = "DTXSID7020182"`. This creates 834+ test failures because functions receive string DTXSIDs where they expect integers, booleans, or enum values.

**Why it happens:**
Generator follows a "one pattern fits all" approach inherited from stub generation. Since most CompTox API wrappers accept DTXSIDs as the primary query parameter, the test generator assumes this pattern universally. Parameter type introspection is missing — the generator doesn't read function signatures to determine actual parameter types.

**How to avoid:**
- Extract function signatures using `formals()` or parse roxygen `@param` tags for type information
- Build parameter type map from OpenAPI schemas (stored during stub generation)
- Match parameter names to appropriate test values: `limit` → integer, `search_type` → valid enum, `page` → integer
- Never use a single default value for all parameters regardless of name

**Warning signs:**
- Test error messages like `argument of length 0` or `invalid type (character) for parameter 'limit'`
- VCR cassettes recording requests with obviously wrong parameter values
- High test failure rate (>50%) immediately after generation
- Functions with pagination (`limit`, `page`, `offset`) failing universally

**Phase to address:**
Phase 1 (Fix Build Blockers) — This breaks the entire test suite and prevents iterative development.

---

### Pitfall 2: tidy=FALSE / Tibble Assertion Mismatch

**What goes wrong:**
122 stub functions return lists (`tidy=FALSE` in `generic_request()` call) but auto-generated tests assert `expect_s3_class(result, "tbl_df")`. Tests fail with "object does not inherit from 'tbl_df'" even though the function works correctly.

**Why it happens:**
Test generator doesn't inspect the actual `tidy` parameter value in stub implementations. It assumes all functions return tibbles (the most common case) without verifying. The `tidy` parameter is often buried in `generic_request()` calls, and automated extraction requires parsing R code, not just reading signatures.

**How to avoid:**
- Parse stub source files to extract `tidy=` argument values from `generic_request()` calls
- Store `tidy` flag in stub generation metadata (add to endpoint spec during `render_endpoint_stubs()`)
- Generate tests that match actual return type: `tidy=TRUE` → expect tibble, `tidy=FALSE` → expect list
- Test generators should read implementation, not guess behavior

**Warning signs:**
- Mass test failures with "does not inherit from class" errors
- Tests failing for functions that are documented to return lists
- VCR cassettes recorded successfully (request worked) but assertion fails

**Phase to address:**
Phase 1 (Fix Build Blockers) — High failure rate blocks useful coverage metrics and CI reporting.

---

### Pitfall 3: VCR Cassettes Recorded with Wrong Parameter Values

**What goes wrong:**
673 untracked VCR cassettes were recorded from production API with incorrect parameter values (due to Pitfall 1). These cassettes contain error responses or unexpected behavior because the API received malformed requests. Committing them pollutes the test fixture directory, and re-recording requires 300+ production API calls.

**Why it happens:**
Test generation ran BEFORE parameter type detection was fixed. VCR recorded the initial test execution, capturing API responses to bad requests. Developer didn't validate cassettes before committing, assuming "test ran = test works."

**How to avoid:**
- **NEVER commit VCR cassettes from first test run without validation**
- Review cassettes for HTTP error codes (4xx/5xx) and empty/error response bodies
- Use `check_cassette_safety()` helper to detect API keys and malformed requests
- Delete cassettes before fixing test generator, then re-record with correct params
- Rate-limit mass re-recording to avoid production API throttling

**Warning signs:**
- Git status shows hundreds of untracked `.yml` files in `tests/testthat/fixtures/`
- Cassettes contain HTTP 400/422 responses ("invalid parameter")
- Cassettes show parameter values that don't match function purpose (DTXSID where formula expected)
- Tests pass but inspect cassette and see empty `data` arrays with error messages

**Phase to address:**
Phase 2 (Clean VCR Cassettes) — Must nuke bad cassettes AFTER fixing test generator in Phase 1.

---

### Pitfall 4: Mass API Re-recording Without Rate Limit Awareness

**What goes wrong:**
Re-recording 300+ cassettes from production EPA CompTox API triggers rate limiting, IP bans, or quota exhaustion. Tests start failing mid-batch with 429 errors, leaving partial cassette set (some old, some new). Production API becomes unavailable for actual users during mass re-recording.

**Why it happens:**
Test generator runs all tests sequentially without delays. EPA APIs have undocumented rate limits (not in public docs). Developer assumes "API key = unlimited access" and runs full test suite in CI, hitting production repeatedly.

**How to avoid:**
- **Batch cassette re-recording**: Delete and re-record 20-50 cassettes at a time, not all 300+
- Add `Sys.sleep(0.5)` between requests during initial recording (remove for replay)
- Check API responses for rate limit headers (`X-RateLimit-Remaining`, `Retry-After`)
- Use staging/dev endpoints for mass testing if available (`ctx_server(2)`)
- Never run full cassette re-recording in CI (record locally, commit cassettes)

**Warning signs:**
- Tests fail with HTTP 429 ("Too Many Requests")
- API responses include "quota exceeded" messages
- First 100 tests pass, next 200 fail with connection errors
- Production API documentation mentions "fair use" policies

**Phase to address:**
Phase 2 (Clean VCR Cassettes) — Rate limiting is discovered during mass re-recording attempts.

---

### Pitfall 5: Pipeline Tests Reference dev/ Files Missing in Built Package

**What goes wrong:**
6 `test-pipeline-*.R` files call `source_pipeline_files()` which loads scripts from `dev/endpoint_eval/`. During `R CMD check`, these tests fail because `dev/` directory is excluded via `.Rbuildignore`. Tests pass locally but fail in CI package checks.

**Why it happens:**
Test files were created during development when `dev/` utilities were being built. Developer assumed test environment = development environment. R package convention excludes `dev/` from built package, but tests didn't account for this.

**How to avoid:**
- **NEVER reference `dev/` directory from `tests/` files**
- Move shared test utilities to `tests/testthat/helper-*.R` (included in built package)
- If testing pipeline code itself, use `testthat::skip_if_not_installed("here")` + `testthat::skip_if(!dir.exists("dev"))`
- Tag pipeline tests with `@tests manual` in roxygen to exclude from `R CMD check`

**Warning signs:**
- Tests pass with `devtools::test()` but fail with `devtools::check()`
- Error messages like "cannot open file 'dev/...': No such file or directory"
- CI build logs show "test failures" but local runs succeed

**Phase to address:**
Phase 1 (Fix Build Blockers) — Prevents package from passing `R CMD check`, blocks CRAN submission.

---

### Pitfall 6: API Keys Leaked in VCR Cassettes

**What goes wrong:**
VCR records full HTTP requests including `x-api-key` header. If `vcr_configure(filter_sensitive_data)` is misconfigured or API key stored in wrong environment variable, cassettes contain plaintext API keys. Committing to GitHub exposes keys publicly.

**Why it happens:**
`vcr_configure()` runs once at test initialization. If API key is set AFTER configuration (e.g., in individual tests), filtering doesn't apply. API key environment variable name mismatch (`CTX_API_KEY` vs `ctx_api_key`) causes filter to miss actual key.

**How to avoid:**
- Configure VCR filtering in `tests/testthat/helper-vcr.R` (runs BEFORE tests)
- Filter both common and actual variable names: `list("<<<API_KEY>>>" = Sys.getenv("ctx_api_key"))`
- Use `check_cassette_safety()` to scan for common key patterns before committing
- Store API keys in `.Renviron`, never hardcode in tests
- Add cassette review step to PR checklist

**Warning signs:**
- Cassettes contain header entries like `x-api-key: sk-live-a1b2c3d4e5f6...`
- Security scanner flags repository with "Exposed API Key" alert
- API provider sends "suspicious activity" email after cassettes committed

**Phase to address:**
Phase 0 (Pre-Generation Setup) — Must configure BEFORE recording any cassettes.

---

### Pitfall 7: Coverage Thresholds Fail Due to Untestable Generated Code

**What goes wrong:**
CI coverage enforcement requires 70% floor, but auto-generated stubs include error handling and debug code paths that are never executed in normal operation. Coverage reports show 60% coverage even though all user-facing functionality is tested, causing CI to fail.

**Why it happens:**
Stubs include defensive code for edge cases (NULL responses, malformed JSON, debug mode branches) that don't occur with VCR-mocked responses. Coverage tools don't distinguish between "never executed" and "not tested" code.

**How to avoid:**
- Exclude auto-generated stub files from coverage calculation (use `covr::package_coverage(exclude_pattern = "^R/ct_.*_bulk\\.R$")`)
- Set LOWER coverage threshold for auto-generated code vs handwritten functions
- Focus coverage on integration paths (user-facing functions) not internal stubs
- Use `# nocov start` / `# nocov end` comments around defensive edge cases

**Warning signs:**
- Coverage reports show low coverage for files with 100% functional test coverage
- `if (debug_mode)` branches marked as uncovered (never TRUE in tests)
- Coverage percentage drops after adding new stubs, even though existing tests pass

**Phase to address:**
Phase 3 (CI Coverage Enforcement) — Coverage thresholds can't be enforced until handled.

---

### Pitfall 8: Stub Generator Produces Invalid R Syntax

**What goes wrong:**
Stub generator emits `"RF" <- model = "RF"` (invalid R assignment) or duplicate `endpoint` arguments (`endpoint = "...", ..., endpoint = "..."`). This kills `R CMD check` code analysis and prevents package from building.

**Why it happens:**
Template string escaping fails when schema parameter names match R reserved words. Duplicate argument bug occurs when parameter extraction runs twice (once for path params, once for query params) and doesn't deduplicate. Generator wasn't tested against schemas with reserved-word parameters.

**How to avoid:**
- Test stub generator against reserved-word parameter names (`model`, `if`, `function`, etc.)
- Escape R reserved words in generated signatures: `model` → `` `model` ``
- Deduplicate parameters during stub rendering, not just during extraction
- Run `R CMD check` on generated stubs BEFORE committing (CI gate)

**Warning signs:**
- Package fails to load with "unexpected '=' in '...'" parse errors
- `devtools::document()` crashes with syntax errors
- Generated function files have red syntax highlighting in editor

**Phase to address:**
Phase 1 (Fix Build Blockers) — Package won't build until fixed.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Generate tests without parameter type detection | Fast initial test coverage | 834 failures, all cassettes need re-recording | Never — parameter types are essential |
| Commit cassettes from first run without review | Quick test fixture creation | API keys leaked, bad requests recorded, security risk | Never — cassettes go to public repo |
| Hard-code DTXSID test values in generator | Simple single-source test data | Fails for non-DTXSID parameters, limits test coverage | Only for prototype/demo |
| Skip cassette safety checks | Faster development cycle | Secrets exposed, credential rotation required | Never — security non-negotiable |
| Use same coverage threshold for generated & handwritten code | Simpler CI configuration | False negatives (good code fails coverage), developer frustration | Only if excluding generated code from coverage |
| Record all cassettes in one CI run | Automated fixture creation | Rate limit bans, partial fixture sets, broken tests | Never with production APIs — batch locally |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| EPA CompTox API | Assuming unlimited requests with API key | Batch requests with delays, use staging for tests |
| VCR cassette recording | Recording during CI, hitting production API | Record locally with valid key, commit cassettes |
| Test generation | Generating tests before fixing stubs | Fix stubs → generate tests → record cassettes (sequence matters) |
| API authentication | Setting key AFTER vcr_configure() | Configure VCR with filter in `helper-vcr.R` (runs first) |
| Coverage reporting | Including generated stubs in coverage calculations | Exclude auto-generated files or use lower threshold |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Recording all cassettes sequentially | First 50 tests pass, rest fail with 429 errors | Batch recording (20-50 at a time) with delays | ~100-200 requests in short time |
| Synchronous API calls in tests | Test suite takes 30+ minutes | Use VCR for replay (ms not seconds per test) | >50 API-dependent tests |
| No deduplication in test generation | Duplicate test files, merge conflicts | Check existing tests before generation | >200 generated tests |
| Unbatched API requests | Individual calls for each DTXSID | Use bulk endpoints where available | >20 chemicals per query |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Committing cassettes with API keys | Public exposure of credentials, quota theft | Configure `filter_sensitive_data` in VCR, scan before commit |
| Using production keys in CI | Key exposure in CI logs, compromised secrets | Use staging API or mock server in CI, never log keys |
| Hardcoding API keys in tests | Keys in git history forever | Always use `Sys.getenv()`, store in `.Renviron` |
| Skipping cassette review | Credentials in YAML headers | Manual review or automated `check_cassette_safety()` |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Failing silently when cassettes missing | Tests pass but don't actually call API | vcr::check_cassette_names = "error" mode |
| Unclear test failure messages | "Assertion failed" doesn't explain what went wrong | Custom expectations with context messages |
| No guidance for re-recording cassettes | Users don't know how to update fixtures | Document in README with `delete_cassettes()` helper |
| Tests require API key to run | Contributors can't validate changes | VCR cassettes allow tests without live API access |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Generated tests:** Check parameter types match function signature (not just "test exists")
- [ ] **VCR cassettes:** Verify HTTP status codes are 200-level (not 4xx/5xx errors)
- [ ] **Coverage reports:** Exclude auto-generated code or set realistic thresholds (not default 80%)
- [ ] **API keys:** Scan cassettes for `x-api-key`, `authorization`, `bearer` headers before commit
- [ ] **Test assertions:** Match actual return type from stub (`tidy` flag determines list vs tibble)
- [ ] **Rate limiting:** Check API responses for `X-RateLimit-Remaining` headers during recording
- [ ] **Cassette safety:** Run `check_cassette_safety()` on all new fixtures
- [ ] **Build validation:** Run `R CMD check` after generating stubs (catches syntax errors)

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| API keys in cassettes | HIGH | 1. Revoke exposed keys, 2. Rotate credentials, 3. Re-record all cassettes, 4. Force-push to remove from history |
| Wrong parameter types in tests | MEDIUM | 1. Fix test generator, 2. Delete bad cassettes, 3. Regenerate tests, 4. Re-record 20-50 cassettes at a time |
| tidy flag mismatch | LOW | 1. Parse stubs for `tidy=`, 2. Regenerate assertions to match, 3. Cassettes are OK (don't re-record) |
| Rate limit ban | MEDIUM | 1. Wait for ban expiry (24h typical), 2. Switch to staging endpoint, 3. Batch future recordings |
| Invalid generated syntax | MEDIUM | 1. Fix template escaping, 2. Regenerate stubs, 3. Run `devtools::document()`, 4. Re-run tests |
| Coverage threshold failures | LOW | 1. Exclude generated files from coverage, OR 2. Lower threshold for auto-generated code |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Blind DTXSID test generation | Phase 1 (Fix Build) | All tests use appropriate types, no `limit = "DTXSID..."` |
| tidy flag mismatch | Phase 1 (Fix Build) | Assertions match `tidy=` value, no "does not inherit" errors |
| API keys in cassettes | Phase 0 (Pre-Gen Setup) | `check_cassette_safety()` passes on all fixtures |
| Invalid stub syntax | Phase 1 (Fix Build) | `R CMD check` passes with 0 errors |
| Pipeline tests reference dev/ | Phase 1 (Fix Build) | `devtools::check()` passes, no file path errors |
| Bad cassettes committed | Phase 2 (Clean VCR) | All cassettes have HTTP 200, valid response bodies |
| Rate limit exhaustion | Phase 2 (Clean VCR) | Batched recording with delays, no 429 errors |
| Coverage threshold failures | Phase 3 (CI Enforcement) | Coverage >70% for handwritten, >50% for generated |

## Sources

**R Package Testing:**
- [HTTP testing in R - Managing cassettes](https://books.ropensci.org/http-testing/managing-cassettes.html)
- [HTTP testing in R - Security with vcr](https://books.ropensci.org/http-testing/vcr-security.html)
- [vcr package documentation](https://cran.r-project.org/web/packages/vcr/vignettes/vcr.html)
- [testthat package documentation](https://testthat.r-lib.org/)
- [R Packages (2e) - Testing basics](https://r-pkgs.org/testing-basics.html)

**Code Coverage:**
- [covr: Test Coverage for Packages](https://covr.r-lib.org/)
- [GitHub - r-lib/covr](https://github.com/r-lib/covr)

**API Rate Limiting:**
- [API Rate Limiting 2026 Guide](https://www.levo.ai/resources/blogs/api-rate-limiting-guide-2026)
- [Rate Limiting AI APIs with Async Middleware](https://dasroot.net/posts/2026/02/rate-limiting-ai-apis-async-middleware-fastapi-redis/)
- [EPA CompTox APIs Documentation](https://www.epa.gov/comptox-tools/computational-toxicology-and-exposure-apis)

**Package Development:**
- [devtools::check() reference](https://devtools.r-lib.org/reference/check.html)
- [R CMD check documentation](https://cran.r-project.org/web/packages/devtools/devtools.pdf)

**Project-Specific:**
- `C:\Users\sxthi\Documents\ComptoxR\TODO.md` (current issues)
- `C:\Users\sxthi\Documents\ComptoxR\.planning\PROJECT.md` (milestone context)
- `C:\Users\sxthi\Documents\ComptoxR\tests\generate_tests_v2.R` (test generator implementation)

---
*Pitfalls research for: R API Wrapper Package Test Infrastructure (ComptoxR)*
*Researched: 2026-02-26*
