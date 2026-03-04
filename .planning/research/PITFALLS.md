# Pitfalls Research

**Domain:** R API wrapper package function migration and stabilization
**Researched:** 2026-03-04 (updated from 2026-02-26)
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Poisoned VCR Cassettes

**What goes wrong:**
Tests record HTTP error responses (401, 403, 500, 503) into cassettes, then replay those failures forever. Functions appear broken when they're actually fine — the cassette contains a stale error response.

**Why it happens:**
- API key expires or is not set during initial recording
- API endpoint returns transient error (rate limit, server downtime) during cassette recording
- Parameter mismatch sends invalid request that gets recorded with its error response
- VCR records whatever happens first — if that's an error, that's what gets saved

**How to avoid:**
- **Before first recording:** Verify API key is valid with manual test call
- **Check cassette status codes:** Run `check_cassette_errors()` helper after recording
- **Delete bad cassettes immediately:** Use `check_cassette_errors(delete = TRUE)` to remove 4xx/5xx cassettes
- **Two-run verification:** After recording, run tests twice — first to record, second to verify playback works

**Warning signs:**
- All tests for a function fail with same error
- Test failures mention 401/403/5xx status codes
- Cassette YAML contains `status: 403` or `status: 500`
- Tests pass once (during recording) but fail on subsequent runs

**Phase to address:**
Phase 1 (Test audit and cleanup) — scan all 717 cassettes with `check_cassette_errors()`, delete poisoned ones before migration

---

### Pitfall 2: Parameter Type Mismatch in Auto-Generated Tests

**What goes wrong:**
Test generator blindly passes DTXSIDs to every first parameter regardless of type. Results in nonsense like `limit = "DTXSID7020182"` or `search_type = "DTXSID7020182"`. Tests run but exercise wrong code paths, giving false sense of coverage.

**Why it happens:**
- Generator uses fallback logic: "If I don't know the parameter type, use a DTXSID"
- Most API wrapper functions DO take DTXSID as first parameter (query, dtxsid)
- Pattern works 90% of the time, fails silently 10% of the time
- No validation that test value matches parameter semantics

**How to avoid:**
- **Enhance test generator priority:** Check parameter NAME before falling back to DTXSID
- **Use parameter name patterns:** If name contains "limit|count|size" → integer; "type|mode" → string enum
- **Manual review:** Audit generated tests before first cassette recording
- **Type checking:** Add assertion in test template to verify parameter type matches expected

**Warning signs:**
- Test calls succeed but return empty results
- Function signature takes `limit` but test passes `"DTXSID7020182"`
- Cassette shows GET request with nonsense query parameters
- Function has no `query` or `dtxsid` parameter but test generator used DTXSID anyway

**Phase to address:**
Phase 1 (Fix test generator) — improve `get_test_value_for_param()` pattern matching before generating new tests for migrated functions

---

### Pitfall 3: Tidy Flag Mismatch

**What goes wrong:**
Function returns a list (`tidy = FALSE`) but test asserts `expect_s3_class(result, "tbl_df")`. Or vice versa. Test fails even though function works correctly. Currently affects 122 functions.

**Why it happens:**
- Test generator defaults to `tidy = TRUE` assumption (most common case)
- Generator's `extract_tidy_flag()` doesn't catch all patterns:
  - Pass-through: `tidy = tidy` (function forwards its own parameter)
  - Conditional: `if (annotate) tidy = TRUE else tidy = FALSE`
  - Implicit: `generic_request()` defaults to `TRUE` when not specified
- Generated stubs sometimes use `tidy = FALSE` for endpoints that return complex nested structures

**How to avoid:**
- **Read the actual call:** Generator must parse `generic_request()` call in function body
- **Default to TRUE correctly:** If tidy parameter absent from generic_request call, it defaults to TRUE
- **Handle pass-through:** If function signature has `tidy` parameter with no default, assume TRUE
- **Manual override:** Test manifest should allow `tidy_override: false` for known list-return functions

**Warning signs:**
- Test expects tibble but gets list error
- Test expects list but gets tibble error
- Function documentation says "returns list" but test asserts tibble
- Batch of new tests all fail with same assertion error

**Phase to address:**
Phase 2 (Thin wrapper migration) — verify tidy flag for each migrated function before generating tests

---

### Pitfall 4: Cassette Name Collisions

**What goes wrong:**
Multiple test variants (single, batch, with annotate) overwrite each other's cassettes. Second test to run gets the wrong cached response. Or wrapper function and stub function both use same cassette name, causing cross-contamination.

**Why it happens:**
- Default cassette naming: `"{function_name}_single"`, `"{function_name}_batch"`
- Doesn't account for parameter variants: `ct_bioactivity(annotate = TRUE)` vs `ct_bioactivity(annotate = FALSE)`
- Wrapper delegates to stub but both use cassettes named after same endpoint
- Re-recording one test variant accidentally overwrites cassette from different variant

**How to avoid:**
- **Include parameter variants in name:** `"{function_name}_{variant}_single"` where variant = "annotate" or "dtxsid_search"
- **Namespace by function type:** User-facing wrappers use `ct_bioactivity_*`, stubs use `ct_bioactivity_data_search_*`
- **Check manifest before recording:** If cassette exists, compare parameter signature
- **Unique names for dispatch patterns:** `ct_bioactivity(search_type = "aeid")` → `"ct_bioactivity_aeid_single"`

**Warning signs:**
- Test passes individually but fails when run as suite
- Cassette contains request for wrong parameters
- Request body shows DTXSIDs when test called with AEID
- Recording second test causes first test to fail

**Phase to address:**
Phase 2 (Thin wrappers) and Phase 3 (Complex dispatchers) — establish cassette naming convention before migrating dispatch functions

---

### Pitfall 5: Post-Processing Logic Lost in Regeneration

**What goes wrong:**
User-facing function has valuable post-processing (coerce lists, join annotations, filter results) but stub regeneration overwrites it. Post-processing must be manually re-added after every schema update.

**Why it happens:**
- Generated stubs are pure API wrappers (query → request → response)
- User-facing functions add value on top: `ct_bioactivity()` can join assay annotations, `ct_lists_all()` can coerce comma-separated strings
- Lifecycle protection prevents STABLE functions from being overwritten
- But during migration, functions are still EXPERIMENTAL — one schema update could wipe post-processing

**How to avoid:**
- **Promote to STABLE early:** As soon as post-processing is added and tested, add `@lifecycle stable`
- **Separate wrapper from stub:** User function `ct_bioactivity()` delegates to generated `ct_bioactivity_data_search_bulk()`, never calls `generic_request()` directly
- **Deferred recipe system:** Track post-processing recipes in separate YAML, auto-apply during generation (deferred to post-v2.2)
- **Test the delta:** Tests should verify post-processing (annotation join, coercion) not just that API call succeeds

**Warning signs:**
- Schema update PR shows diff removing coerce/split logic
- Function suddenly returns raw API response instead of processed tibble
- Conditional projection logic (`if (return_dtxsid) projection = "withdtxsids"`) gets removed
- User reports "function used to join annotations, now it doesn't"

**Phase to address:**
Phase 3 (Complex functions) — ensure lifecycle badges added BEFORE adding post-processing logic

---

### Pitfall 6: Premature Lifecycle Promotion

**What goes wrong:**
Function promoted to `@lifecycle stable` before it's truly stable. Now stuck supporting incomplete implementation or awkward API because breaking changes require deprecation cycle.

**Why it happens:**
- Pressure to show progress: "We migrated 14 functions to stable!"
- Misunderstanding lifecycle promise: STABLE means "breaking changes need deprecation", not "code is bug-free"
- Function appears complete (tests pass, docs exist) but edge cases not considered
- Eager to protect from stub regeneration — use STABLE as protection mechanism

**How to avoid:**
- **Stable checklist:**
  - [ ] All parameters tested (not just happy path)
  - [ ] Error handling verified (API errors, network failures)
  - [ ] Return type won't change (tibble vs list decided)
  - [ ] Parameter names final (won't rename `query` to `dtxsid`)
  - [ ] Post-processing complete (won't add new transformations)
  - [ ] Documentation reviewed by user
- **Use maturing as transition:** Functions can be `@lifecycle maturing` — users can rely on them, but breaking changes possible
- **Separate protection from stability:** Stub generator protects maturing AND stable, not just stable
- **User testing period:** Keep experimental/maturing for at least one release cycle

**Warning signs:**
- Function promoted to stable same day as migration PR
- No user testing between experimental and stable
- Debate about whether to add new parameter: "But it's already stable!"
- Documentation says stable but has TODOs or "not yet implemented"

**Phase to address:**
Phase 4 (Lifecycle review) — audit STABLE candidates, demote any that don't meet checklist

---

### Pitfall 7: Test Manifest Ignored During Regeneration

**What goes wrong:**
Test generator creates `test-ct_function.R`, developer manually improves it (adds edge cases, better assertions), marks protected in manifest, but later regeneration script doesn't check manifest and overwrites manual improvements.

**Why it happens:**
- Manifest check happens in `generate_test_file()` but not in calling scripts
- CI automation runs `generate_all_tests(force = TRUE)` ignoring protection
- Developer doesn't know manifest exists or how to mark tests protected
- Regeneration scripts bypass manifest (direct file writes)

**How to avoid:**
- **Enforce manifest in CI:** `generate_all_tests()` must respect `status: protected` in manifest
- **Never use force=TRUE in CI:** Force flag should only be used in manual regeneration after schema update
- **Auto-protect on edit:** Git pre-commit hook detects manual test edits, adds to manifest
- **Visual indication:** Test file header comment shows: `# Status: protected (last edited 2026-03-01)`

**Warning signs:**
- Developer complains "I fixed this test yesterday, why is it broken again?"
- Test file diff shows reversion to auto-generated version
- Manifest has `status: protected` but file was regenerated anyway
- CI log shows "Generated X tests" including files that should be protected

**Phase to address:**
Phase 1 (Test infrastructure audit) — verify manifest protection works, add pre-commit hook

---

### Pitfall 8: 297 Pre-Existing Failures Mask New Failures

**What goes wrong:**
Test suite already has 297 failures. New migration breaks 5 more tests but no one notices because test failure count is always high. Regression goes undetected until user reports bug.

**Why it happens:**
- "Some tests fail" becomes normalized — team stops investigating failures
- CI shows red but PR gets merged anyway
- New failures hidden in noise: 297 → 302 doesn't trigger alarm
- No baseline: "Is this new or was it already broken?"

**How to avoid:**
- **Quarantine broken tests:** Move to `tests/testthat/broken/` directory (not run by default)
- **Track failure count:** CI fails if failure count INCREASES from baseline
- **Fix in stages:** Phase 1 = audit (categorize failures), Phase 2 = fix VCR issues, Phase 3 = fix code issues
- **Per-function CI:** Migration PR for `ct_hazard()` must pass `test-ct_hazard.R` even if other tests fail
- **Protected functions:** STABLE functions must have passing tests, EXPERIMENTAL can be broken

**Warning signs:**
- PR review comment: "Tests were already failing, not my problem"
- Test failure count steadily increases over time
- Developer runs `devtools::test()` and immediately Ctrl+C because "it'll fail anyway"
- No one knows which tests are expected to fail

**Phase to address:**
Phase 1 (Test audit) — categorize all 297 failures, quarantine unfixable ones, prioritize fixable ones

---

### Pitfall 9: Cassette Re-recording with Wrong Parameters

**What goes wrong:**
Original test had parameter bug (wrong type, wrong value), cassette recorded bad request, developer fixes parameter but re-runs test without deleting cassette. VCR replays old request, test still fails, developer confused why fix didn't work.

**Why it happens:**
- VCR matches on request signature (method + URI + body by default)
- Fixed parameter changes request body → no longer matches cassette
- VCR tries to make real HTTP call, but API key not set in CI environment
- Or VCR's "if cassette exists, must use it" rule prevents new recording
- Developer doesn't realize cassette must be deleted for fix to work

**How to avoid:**
- **Document re-recording workflow:**
  1. Fix parameter bug in test code
  2. Delete cassette: `delete_cassettes("function_name*")`
  3. Verify API key set: `Sys.getenv("ctx_api_key")`
  4. Run test to record: `testthat::test_file("test-ct_function.R")`
  5. Verify cassette: `check_cassette_safety("ct_function")`
- **Use record mode once:** `vcr::use_cassette("name", record = "once")` won't re-record if cassette exists
- **CI re-recording:** Separate workflow for "re-record all cassettes" with API key secret

**Warning signs:**
- Developer says "I fixed the parameter but test still fails"
- Error message: "Could not find cassette matching request"
- Cassette modification time older than test file modification time
- Test passes locally (developer has API key) but fails in CI (no key, tries to use cassette)

**Phase to address:**
Phase 1 (Documentation) — write re-recording workflow, add to CLAUDE.md and README

---

### Pitfall 10: Dispatch Pattern Cassette Explosion

**What goes wrong:**
Function like `ct_bioactivity()` dispatches to 4 different endpoints based on `search_type` parameter. Each combination needs cassette: single+dtxsid, batch+dtxsid, single+aeid, batch+aeid, single+spid... = 12+ cassettes for one function. Recording/maintaining becomes overwhelming.

**Why it happens:**
- Dispatch pattern multiplies test variants: 4 search types × 3 test variants (single/batch/error) = 12 cassettes
- Each cassette must be recorded, verified, maintained
- Schema update may affect only one endpoint but all cassettes must be re-checked
- Easy to forget a variant: "Did I test annotate=TRUE with search_type='spid'?"

**How to avoid:**
- **Minimal cassette strategy:** Only record happy path for each search_type, skip batch variants for dispatch tests
- **Separate dispatch from execution:** Test dispatch logic (which function gets called) without cassettes, test execution with cassettes in stub tests
- **Parameterized tests:** Use `testthat::test_that()` with loop over search_types, single cassette per type
- **Stub testing priority:** User-facing function tests dispatch, generated stub tests test API interaction

**Warning signs:**
- Test file has 15+ `use_cassette()` blocks
- Developer avoids adding test variant because "too many cassettes"
- Test failure in one variant, unclear if other variants broken too
- CI takes 10+ minutes to record cassettes for one function

**Phase to address:**
Phase 3 (Complex dispatchers) — establish cassette strategy for dispatch patterns before migrating `ct_bioactivity()`

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip VCR cassette for "simple" functions | Tests run fast without API key | Silent breakage when API response format changes | Never — even simple endpoints need cassette verification |
| Copy-paste test from similar function | Fast test creation | Wrong assertions, parameter types; spreads bugs to new tests | Acceptable for rapid prototyping IF reviewed before commit |
| Mark all functions STABLE to prevent regeneration | Protection from stub overwrite | Stuck supporting half-baked API, can't iterate without deprecation | Never — use `maturing` or improve stub generator protection |
| Use generic DTXSID test value for all functions | Generator logic simple, works 90% of time | 10% silent failures (wrong parameter types) | Acceptable as fallback IF name-based matching tried first |
| Commit cassettes without safety check | Fast iteration | Leak API keys, credentials | Never — must run `check_cassette_safety()` before commit |
| Defer fixing pre-existing test failures | Can focus on new features | New failures hidden in noise, regression detection impossible | Acceptable short-term IF failures tracked and quarantined |
| Use same cassette name for wrapper and stub | Simpler organization | Cross-contamination, test failures when both run | Never — must namespace by function type |

## Integration Gotchas

Common mistakes when connecting VCR, testthat, generic_request, and stub generator.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| VCR + httr2 | Assume VCR auto-detects parameter changes | Must manually delete cassettes after fixing parameter bugs, VCR won't auto-invalidate |
| testthat + auto-generation | Overwrite manually-improved tests | Check test manifest for `status: protected` before regeneration |
| generic_request + tidy flag | Test assumes `tidy = TRUE` (default) but function passes `tidy = FALSE` | Generator must read actual `tidy` parameter from `generic_request()` call |
| Stub regeneration + lifecycle | Regenerate STABLE function, lose post-processing | Stub generator must check for `@lifecycle stable` and skip, or use wrapper pattern |
| VCR + API errors | Record 403/500 error, replay forever | Check cassettes with `check_cassette_errors()`, delete bad ones before committing |
| Test generator + dispatch | Generate one cassette name for function with multiple search_type variants | Include variant in cassette name: `ct_bioactivity_dtxsid_single` |
| CI + re-recording | Try to re-record cassettes without API key | Either: (1) skip cassette tests in CI if API key missing, or (2) provide key as secret |
| Wrapper + stub testing | Test both in isolation, cassette names collide | Use different cassette prefixes: `ct_bioactivity_*` for wrapper, `ct_bioactivity_data_search_*` for stub |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Record cassette for every test variant | Test recording takes 30+ minutes with 1000+ cassettes | Use parameterized tests, reduce cassette count, test dispatch logic separately | >500 cassettes or >100 endpoints |
| Re-record ALL cassettes after every schema change | Hours-long CI runs, developer avoidance | Detect which endpoints changed, only re-record affected cassettes | >200 cassettes |
| Test generator parses every R file on every run | Slow test generation (>5 minutes) | Cache parsed metadata, only re-parse changed files | >300 R files |
| Commit all 717 cassettes to repo | Git slow, PRs huge, merge conflicts frequent | Use Git LFS for cassettes, or store cassettes in CI artifacts | >500 cassettes or >50 MB total |
| Run full test suite on every commit | CI takes 20+ minutes, developers stop using CI | Split into fast unit tests (no cassettes) and slow integration tests (with cassettes) | >1000 tests or >297 failures |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Commit cassette without filtering API key | Key leaked in public repo | Always configure `filter_sensitive_data` in vcr_configure(), verify with `check_cassette_safety()` |
| Hard-code API key in test | Key in version control, exposed to all contributors | Use environment variable, document in .env.example (not .env) |
| Include PII in cassette | GDPR/HIPAA violation, chemical data exposure | Filter query parameters, use synthetic test data (DTXSID7020182 = Bisphenol A, public) |
| Record production API calls with real user data | Expose confidential research | Use staging API for recording, or use synthetic/public chemical identifiers |
| Share cassettes with API errors containing auth details | Error messages may contain token fragments | Check cassettes for `Authorization:` headers, `Bearer` tokens before committing |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Migrated function:** Tests pass but cassettes recorded with wrong parameters — verify parameter types match function signature
- [ ] **Lifecycle badge:** Function marked STABLE but post-processing not complete — verify all planned features implemented
- [ ] **Test coverage:** Function has tests but only happy path — verify error cases, edge cases, batch requests tested
- [ ] **VCR cassettes:** Cassettes exist but contain HTTP errors — run `check_cassette_errors()` to verify clean responses
- [ ] **Documentation:** Roxygen docs exist but examples not tested — run examples manually, verify outputs correct
- [ ] **Wrapper function:** Delegates to stub but doesn't add value — verify post-processing, parameter validation, or user-friendly errors added
- [ ] **Dispatch pattern:** Switch statement routes to stubs but variants not all tested — verify cassette per search_type
- [ ] **Test manifest:** File marked protected but not in manifest — verify entry in `dev/test_manifest.json` with status and date
- [ ] **API key filtering:** Cassette recorded but VCR filter not configured — verify `<<<API_KEY>>>` placeholder in YAML, not actual key
- [ ] **Lifecycle protection:** Function STABLE but stub generator can still overwrite — verify generator checks for `@lifecycle stable` tag

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Poisoned cassettes | LOW | (1) Run `check_cassette_errors(delete = TRUE)`, (2) verify API key set, (3) re-run tests to record clean cassettes |
| Parameter type mismatch | LOW | (1) Fix test to use correct parameter type, (2) delete cassette, (3) re-record with correct request |
| Tidy flag mismatch | LOW | (1) Check actual `tidy` parameter in function, (2) update test assertion (tibble vs list), (3) no cassette change needed |
| Cassette name collision | MEDIUM | (1) Rename cassettes to include variant, (2) update test to use new names, (3) delete old cassettes, (4) re-record |
| Post-processing lost | MEDIUM | (1) Restore from git history, (2) add `@lifecycle stable` to prevent future loss, (3) add test for post-processing logic |
| Premature lifecycle promotion | HIGH | (1) Assess breaking change need, (2) if YES: add deprecation warnings, plan migration in next version, (3) if NO: keep as-is, document limitations |
| Test manifest ignored | LOW | (1) Restore protected tests from git, (2) verify manifest entries exist, (3) update generator to check manifest |
| Pre-existing failures mask new failures | HIGH | (1) Quarantine broken tests, (2) establish baseline failure count, (3) CI fails on increase from baseline, (4) fix in phases |
| Re-recording with wrong parameters | LOW | (1) Delete cassettes, (2) fix parameters in test, (3) verify API key set, (4) re-record |
| Cassette explosion | MEDIUM | (1) Reduce cassette count (test dispatch separately from execution), (2) use parameterized tests, (3) focus on critical variants |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Poisoned cassettes | Phase 1: Test audit | Run `check_cassette_errors()`, count = 0 |
| Parameter type mismatch | Phase 1: Fix test generator | Audit generated tests, verify correct parameter types in all 7 affected files |
| Tidy flag mismatch | Phase 2: Thin wrappers | Each migrated function has test matching actual tidy flag |
| Cassette name collision | Phase 2-3: Migration | No cassette name conflicts between wrappers/stubs or variants |
| Post-processing lost | Phase 3: Complex functions | All functions with post-processing have `@lifecycle stable` before merge |
| Premature lifecycle promotion | Phase 4: Lifecycle review | STABLE checklist verified for each promoted function |
| Test manifest ignored | Phase 1: Test infrastructure | CI logs show "Skipping protected file" when appropriate |
| Pre-existing failures mask new failures | Phase 1: Test audit | Failure count baseline established, CI tracks delta |
| Re-recording workflow | Phase 1: Documentation | Re-recording workflow documented in CLAUDE.md, tested by contributor |
| Cassette explosion | Phase 3: Complex dispatchers | Dispatch functions have ≤3 cassettes per search_type variant |

## Research-Specific Insights

**From project context:**
- **297 pre-existing failures:** Not technical debt — these are from VCR/API key issues in CI environment. Real tests pass locally with API key. Quarantine strategy more appropriate than mass fixing.
- **122 tidy flag mismatches:** Root cause = test generator defaults to `TRUE` but many generated stubs use `tidy = FALSE` for complex nested responses. Fix generator before migrating more functions.
- **33/256 functions have cassettes:** 87% of API wrappers never had tests. Not a "cassette management" problem — it's a test coverage problem. Focus test generation on newly-migrated functions, defer backfilling old untested functions.
- **Lifecycle protection (#95) already implemented:** Generator checks for `@lifecycle stable` and skips. Pattern validated. Use confidently.
- **Wrapper vs stub pattern working:** `ct_hazard()` (wrapper) delegates to `ct_hazard_search_bulk()` (stub). Post-processing in wrapper, API call in stub. This works — extend to complex functions.

**From VCR research:**
- **Request matching critical:** Default = method + URI only. If tests fail after parameter fix, likely need to match on body too: `match_requests_on = c("method", "uri", "body_json")`. Or delete cassette and re-record.
- **Nondeterministic parameters:** If API uses nonce/timestamp, cassette matching will never work. Filter those parameters: `filter_query_parameters = c("timestamp", "nonce")`.
- **Record mode strategies:** Use `:once` for normal development (replay existing), `:new_episodes` to add new interactions without re-recording old ones, `:all` to force complete re-record (dangerous — use only when necessary).

**From httr2 API wrapper research:**
- **User agent politeness:** Generated stubs should set `req_user_agent("ComptoxR/2.2 (https://github.com/...")` — if package causes issues, API maintainers can contact. Currently not implemented — add to stub generator.
- **Credentials security:** Never put API keys in URL parameters, VCR won't redact them. Always use headers. Current implementation correct (`x-api-key` header, filtered in vcr config).
- **Built-in retry/rate-limiting:** httr2 has `req_retry()` and `req_throttle()`. Current implementation uses `req_retry(max_tries = 3, is_transient = is_transient_error)` — good. Not using `req_throttle()` — could add if rate limiting becomes issue.

**From lifecycle research:**
- **Two key promises for STABLE:** (1) Breaking changes avoided where possible, (2) deprecation cycle when needed. Don't promote until both promises can be kept.
- **Maturing is underused:** Many functions marked experimental but are actually maturing (users rely on them, but API might change). Use maturing more liberally.
- **Deprecation cycle = soft-deprecated → deprecated → defunct:** Takes 2-3 releases. Plan timeline before making breaking changes.

## Sources

### VCR and Testing
- [Managing cassettes | HTTP testing in R](https://books.ropensci.org/http-testing/managing-cassettes.html) — cassette naming, re-recording strategies
- [3 tips to tune your VCR in tests | Arkency Blog](https://blog.arkency.com/3-tips-to-tune-your-vcr-in-tests/) — cassette editing pitfalls, workflow best practices
- [VCR returns responses from other cassettes instead of recording new interactions](https://github.com/vcr/vcr/issues/425) — cassette poisoning issue, known bug
- [New record mode "re_record"](https://github.com/vcr/vcr/discussions/864) — re-recording interval strategy
- [Getting started with vcr](https://docs.ropensci.org/vcr/articles/vcr.html) — vcr configuration, filter_sensitive_data
- [Debugging vcr failures](https://docs.ropensci.org/vcr/articles/debugging) — request matching, logging strategy

### R Package Lifecycle
- [Lifecycle stages • lifecycle](https://lifecycle.r-lib.org/articles/stages.html) — experimental/stable/deprecated stages
- [21 Lifecycle – R Packages (2e)](https://r-pkgs.org/lifecycle.html) — lifecycle badge usage, deprecation cycle

### httr2 API Wrappers
- [Wrapping APIs • httr2](https://httr2.r-lib.org/articles/wrapping-apis.html) — user agent, credentials security, rate limiting
- [Best practices for API packages • httr](https://httr.r-lib.org/articles/api-packages.html) — error handling, authentication patterns

### R CMD Check
- [Appendix A — R CMD check – R Packages (2e)](https://r-pkgs.org/R-CMD-check.html) — check errors, warnings, notes

### Project-Specific
- ComptoxR TODO.md (lines 1-100) — 834+ test failures, tidy flag mismatches, parameter type issues
- ComptoxR dev/generate_tests.R — test generator implementation, parameter mapping logic
- ComptoxR tests/testthat/helper-vcr.R — cassette management helpers (delete, check_safety, check_errors)
- ComptoxR R/ct_bioactivity.R — dispatch pattern example (search_type switch)
- ComptoxR R/ct_lists_all.R — post-processing pattern example (coerce/split)

---
*Pitfalls research for: R API wrapper package function migration and stabilization*
*Researched: 2026-03-04 (updated from 2026-02-26)*
