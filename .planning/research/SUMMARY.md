# Project Research Summary

**Project:** ComptoxR v2.2 Package Stabilization
**Domain:** R API wrapper package function migration and stabilization
**Researched:** 2026-03-04
**Confidence:** HIGH

## Executive Summary

ComptoxR v2.2 is a stabilization milestone for an R package that wraps EPA CompTox Dashboard APIs. The project migrates 20+ user-facing functions from custom httr2 implementations to centralized request templates (`generic_request()` and `generic_chemi_request()`), while adding lifecycle badges to signal API stability. This is NOT a feature expansion — it's architectural consolidation. The existing technology stack is complete and proven; migration requires workflow discipline rather than new dependencies.

The recommended approach follows a thin wrapper pattern: user-facing functions (e.g., `ct_hazard()`) delegate to auto-generated API stubs (e.g., `ct_hazard_toxval_search_bulk()`). Generated stubs handle HTTP details through `generic_request()`, while user-facing wrappers add post-processing, parameter validation, or multi-endpoint dispatching. Lifecycle badges protect stable wrappers from regeneration when OpenAPI schemas update. The pattern is proven with 14 existing functions; v2.2 extends it to the remaining unmigrated functions.

Key risks center on test infrastructure fragility: 297 pre-existing test failures (from VCR cassette/API key issues), 122 tests with tidy flag mismatches (expecting tibbles but getting lists), and 673 untracked cassettes recorded with wrong parameters. Mitigation strategy: fix test generator parameter detection, quarantine broken tests, establish cassette quality gates, and use two-phase recording (initial capture → fix errors → re-record clean). Migration complexity splits into four patterns with 10-60 min effort per function, totaling ~15 hours for v2.2 scope (Patterns 1-2 only, deferring complex dispatchers to v2.3).

## Key Findings

### Recommended Stack

The stack is complete — all required dependencies are already in `DESCRIPTION` and functional. No new packages needed. Migration leverages existing infrastructure: httr2 1.2.1 for HTTP, dplyr/tidyr/purrr for post-processing, lifecycle 1.0.5 for stability badges, testthat 3.2.3 + vcr 2.1.0 for testing, roxygen2 7.3.3 for documentation. Generic request templates (`R/z_generic_request.R`) handle batching, authentication, retries, and tidy conversion — migration delegates to them.

**Core technologies:**
- **httr2 1.2.1**: Modern HTTP client with retry/rate-limit support — powers `generic_request()` which handles all API calls
- **lifecycle 1.0.5**: Function lifecycle badges (experimental/stable/deprecated) — already used in 409 functions, protects stable code from stub regeneration
- **vcr 2.1.0**: HTTP replay via YAML cassettes — enables testing without live API calls; 33 cassettes recorded, needs quality audit
- **testthat 3.2.3**: Unit testing with parallel execution — test generator creates metadata-driven tests from function signatures
- **dplyr/tidyr/purrr**: Tidyverse for post-processing — used in complex wrappers (`ct_bioactivity()`, `ct_lists_all()`) for joins, list operations, string splitting

**Critical finding:** The stub generation pipeline (v1.0-v2.1) produces working stubs; test generator (v2.1) has metadata extraction bugs (assumes all parameters are DTXSIDs, doesn't read tidy flag). Fix test generator before migrating more functions.

### Expected Features

**Must have (table stakes):**
- User-facing functions delegate to templates — architectural requirement, all ct_* functions call `generic_request()` or generated stubs
- Lifecycle badges on all exported functions — CRAN expectation, enables stub protection (#95)
- Consistent function signatures — all similar endpoints use same parameter names (e.g., `query`)
- VCR test cassettes for all functions — rOpenSci testing standard, prevents live API calls during CI
- R CMD check passes cleanly — CRAN requirement (0 errors/warnings) before release
- Parameter validation — check query types, validate enums with `match.arg()`

**Should have (competitive):**
- Thin wrapper layer pattern — user-friendly names (`ct_hazard()`) over verbose generated names (`ct_hazard_toxval_search_bulk()`)
- Multi-endpoint dispatcher pattern — single function routes to multiple endpoints (e.g., `ct_bioactivity(search_type = "dtxsid|aeid|spid")`)
- Post-processing layer pattern — transform API responses for R workflows (`ct_lists_all(coerce = TRUE)` splits comma-separated strings)
- Secondary annotation join pattern — enrich data automatically (`ct_bioactivity(annotate = TRUE)` joins assay details)
- Lifecycle-protected stub regeneration — prevents overwriting stable functions during schema updates (#95 already implemented)

**Defer (v2+):**
- S7 class implementation (#29) — return type refactoring, would break user code
- Post-processing recipe system (#120) — wait for pattern to emerge from 5+ functions, currently only 3-4 have complex logic
- Advanced schema handling (ADV-01-04) — nested schemas, discriminators not needed for current APIs
- Session-level result caching — user space concern, package already caches compiled regex in `.ComptoxREnv`

### Architecture Approach

ComptoxR uses a three-layer architecture: (1) auto-generated stubs from OpenAPI schemas handle HTTP mechanics via `generic_request()`, (2) user-facing wrappers delegate to stubs while adding validation/post-processing/dispatching, (3) lifecycle badges protect layer 2 from layer 1 regeneration. Test infrastructure mirrors this: metadata-driven test generator reads function signatures to create cassette-based tests, VCR records API interactions on first run with API key. Integration challenges arise from asynchronous workflows: stub generation runs in CI but test generation is manual, leading to stub-test gaps.

**Major components:**
1. **Generic Request Templates** (`R/z_generic_request.R`) — centralized HTTP handling with batching (default 200 items/POST), authentication (x-api-key header), retries (exponential backoff), tidy conversion via `safe_tidy_bind()`
2. **Stub Generation Pipeline** (`dev/endpoint_eval/`) — parses OpenAPI schemas, generates function stubs with roxygen docs, protects functions marked `@lifecycle stable` from overwrite
3. **Test Generator v2** (`tests/testthat/tools/helper-test-generator-v2.R`) — extracts metadata from function signatures (parameters, return types), generates 4 test types (basic, batch, error, example), creates VCR cassettes with unique names per variant
4. **User-Facing Wrappers** (Pattern library) — Thin Delegation (1-line stub call), Direct Template (calls `generic_request()` with projection), Multi-Endpoint Dispatcher (switch on `search_type`), Post-Processing Transform (conditional logic + data manipulation)

**Integration gap:** Stub generation and test generation are decoupled — no automated trigger to generate tests when stubs are created. Leads to 223 functions without tests (87% untested). Recommended fix: CI workflow that detects stub-test gaps, auto-generates tests, commits both together.

### Critical Pitfalls

1. **Poisoned VCR Cassettes** — tests record HTTP errors (401, 403, 500) into cassettes, then replay failures forever. Function appears broken when it's fine. Fix: run `check_cassette_errors(delete = TRUE)` after recording, verify API key valid, use two-run verification (record → replay).

2. **Parameter Type Mismatch in Auto-Generated Tests** — test generator passes DTXSIDs to all parameters; results in `limit = "DTXSID7020182"` or `search_type = "DTXSID7020182"`. Tests run but exercise wrong code paths. Fix: enhance generator to check parameter NAME patterns (`limit|count|size` → integer, `type|mode` → string enum) before defaulting to DTXSID.

3. **Tidy Flag Mismatch** — function returns list (`tidy = FALSE`) but test expects tibble, or vice versa. Currently affects 122 functions. Fix: test generator must read actual `tidy` parameter from `generic_request()` call in function body, not assume default.

4. **Cassette Name Collisions** — multiple test variants (single, batch, annotate=TRUE) overwrite each other's cassettes. Fix: include parameter variants in cassette names (`ct_bioactivity_dtxsid_single` vs `ct_bioactivity_aeid_single`).

5. **297 Pre-Existing Failures Mask New Failures** — test suite always red, new regressions hidden in noise. Fix: quarantine broken tests to `tests/testthat/broken/`, track failure count baseline, CI fails if count INCREASES.

## Implications for Roadmap

Based on research, suggested phase structure prioritizes fixing test infrastructure before migration, then migrating simple patterns first, deferring complex patterns to v2.3.

### Phase 1: Test Infrastructure Stabilization
**Rationale:** Can't migrate functions confidently with broken test generator. 297 failures and 122 tidy mismatches create noise that masks real issues. Fix foundations first.

**Delivers:**
- Test generator correctly detects parameter types (no more DTXSID→limit bugs)
- Test generator reads tidy flag from function body (correct tibble vs list expectations)
- Cassette quality gates (run `check_cassette_errors()`, reject commits with bad cassettes)
- Failure baseline established (quarantine unfixable tests, track delta)
- Re-recording workflow documented (when to delete cassettes, how to verify API key)

**Addresses (table stakes):**
- R CMD check passes cleanly — requires resolving syntax errors in generated stubs (TODO.md line 8-9)
- VCR test cassettes for all functions — requires clean cassettes, not poisoned ones

**Avoids (pitfalls):**
- Poisoned cassettes (#1) — quality gates prevent committing error responses
- Parameter type mismatch (#2) — generator fixes before creating new tests
- Tidy flag mismatch (#3) — generator reads actual parameter values
- Pre-existing failures masking new failures (#5) — baseline tracking catches regressions

**Estimated effort:** 2-3 days

### Phase 2: Thin Wrapper Migration (Pattern 1)
**Rationale:** Simplest pattern, highest coverage (~60% of functions), lowest risk. Validates migration workflow before tackling complex patterns.

**Delivers:**
- ~21 functions migrated to thin delegation pattern (1-line stub calls)
- Lifecycle badges added (`@lifecycle stable`)
- VCR cassettes recorded for all migrated functions
- Documentation complete (@param, @return, @examples)
- R CMD check passes for migrated functions

**Addresses (table stakes):**
- User-facing functions delegate to templates
- Lifecycle badges on all exported functions
- Consistent function signatures

**Uses (stack):**
- lifecycle 1.0.5 for badges
- vcr 2.1.0 for cassette recording
- roxygen2 7.3.3 for documentation regeneration via `devtools::document()`

**Avoids (pitfalls):**
- Premature lifecycle promotion (#6) — use STABLE checklist before promotion
- Test manifest ignored (#7) — verify protection works for manually-improved tests

**Estimated effort:** 5.25 hours (21 functions × 15 min each)

### Phase 3: Direct Template Migration (Pattern 2)
**Rationale:** Second-simplest pattern, ~20% of functions. Requires projection testing and parameter mapping but no complex post-processing.

**Delivers:**
- ~7 functions migrated to direct template pattern (calls `generic_request()` with endpoint-specific parameters)
- Projection values tested with live API
- VCR cassettes for all projection variants
- Documentation with projection parameter examples

**Addresses (should-have differentiators):**
- Projection-aware wrappers — fine-grained control of API response fields

**Uses (stack):**
- generic_request() with projection parameters
- VCR for multi-variant cassettes (one per projection value)

**Avoids (pitfalls):**
- Cassette name collisions (#4) — include projection in cassette names
- Post-processing lost in regeneration (#5) — add `@lifecycle stable` immediately after post-processing added

**Estimated effort:** 4 hours (7 functions × 35 min each)

### Phase 4: Lifecycle Review and Documentation
**Rationale:** Before release, audit all STABLE promotions and document migration patterns for maintainers.

**Delivers:**
- STABLE checklist verified for all promoted functions
- Migration patterns documented (thin wrapper, direct template examples)
- Troubleshooting guide for test failures
- Cassette re-recording workflow in CLAUDE.md

**Addresses (table stakes):**
- R CMD check passes cleanly (final validation)
- Phased deprecation when renaming (ensure proper lifecycle transitions)

**Avoids (pitfalls):**
- Premature lifecycle promotion (#6) — audit catches functions promoted too early
- Re-recording workflow confusion (#9) — documentation prevents mistakes

**Estimated effort:** 1-2 days

### Phase Ordering Rationale

- **Test infrastructure first** because migrating with broken tests is building on quicksand. Current state: 297 failures, 122 tidy mismatches, 673 bad cassettes. Can't trust test outcomes.
- **Simple patterns before complex** to validate workflow and uncover edge cases early. Pattern 1 (thin wrappers) = 10 min/function; Pattern 3 (dispatchers) = 45 min/function. Learn cheap, scale proven patterns.
- **Defer complex patterns (3-4) to v2.3** because they require deeper testing strategy (cassette explosion for dispatchers, recipe system design for post-processing). v2.2 targets 80% coverage with Patterns 1-2, deferring 20% that needs more design work.
- **Architecture grouping** mirrors migration risk: Pattern 1 has zero post-processing (no regeneration risk), Pattern 2 has simple projection (low risk), Pattern 3 has dispatch logic (medium risk), Pattern 4 has transformation chains (high risk from schema changes).

**Dependency flow:**
```
Phase 1 (test fixes) → enables → Phase 2 (thin wrappers) → validates → Phase 3 (direct templates) → informs → Phase 4 (review)
                                                    ↓
                                          Defer to v2.3: Patterns 3-4 (dispatchers, post-processing)
```

### Research Flags

Phases likely needing deeper research during planning:
- **None for v2.2 scope** — patterns proven, stack complete, architecture stable. Execution is workflow discipline, not discovery.

Phases with standard patterns (skip research-phase):
- **Phase 1** — test generator fixes are debugging, not research. Root causes known (TODO.md documents bugs).
- **Phase 2-3** — migration patterns documented in FEATURES.md (thin wrapper, direct template). Execute, don't research.
- **Phase 4** — lifecycle review uses existing STABLE checklist. Documentation work, not research.

**Future research needs (v2.3+):**
- **Pattern 3 (dispatchers)** — cassette strategy for multi-endpoint functions needs design exploration. How to test 4 search_types × 3 variants without 12 cassettes per function?
- **Pattern 4 (post-processing)** — recipe system architecture (#120) needs concrete examples from 5+ functions before generalizing. Current 3-4 examples insufficient for pattern extraction.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All dependencies in DESCRIPTION and proven in production. httr2 1.2.1 shipped, lifecycle 1.0.5 used in 409 functions, vcr 2.1.0 has 33 working cassettes. No unknowns. |
| Features | HIGH | Table stakes clear from R package standards (CRAN requirements, rOpenSci testing practices). Differentiators proven in existing functions (thin wrapper pattern in `ct_hazard()`, dispatcher in `ct_bioactivity()`). |
| Architecture | HIGH | Three-layer pattern (stubs → wrappers → lifecycle protection) validated in v1.0-v2.1. Test infrastructure gaps documented with solutions (detection-then-generation, metadata-driven tests). |
| Pitfalls | HIGH | Root causes known from TODO.md (297 failures from VCR/API key, 122 from tidy mismatches, 673 bad cassettes from parameter bugs). Recovery strategies tested (check_cassette_errors helper works, manual cassette deletion verified). |

**Overall confidence:** HIGH

Research based on actual codebase analysis (TODO.md, existing functions, test generator source), official documentation (vcr, httr2, lifecycle packages), and proven patterns (14 functions already migrated). No speculation or untested assumptions.

### Gaps to Address

**Test generator metadata extraction robustness:** Current implementation has brittle parsing (assumes `generic_request()` always on one line, doesn't handle pass-through `tidy = tidy` parameter). Need to strengthen AST parsing or use formal code analysis (e.g., `codetools::findGlobals()` to detect function calls). Handle during Phase 1 by testing against all existing migrated functions, fixing edge cases before generating new tests.

**Cassette storage scalability:** At 717 cassettes (target: 256 functions × 3 variants = 768 cassettes), approaching Git repository limits (~50 MB cassette directory). Consider Git LFS or CI artifact storage. Defer decision until cassette count confirmed after migration — may be <500 if dispatch patterns use minimal cassette strategy (test dispatch separately from execution).

**Lifecycle protection verification:** Stub generator claims to respect `@lifecycle stable` (#95) but no automated tests verify this works. Could accidentally overwrite stable function during schema update. Handle during Phase 4 by adding integration test: mark test function STABLE, run stub generator, verify function not overwritten.

**API key management in CI:** Current VCR tests require API key for first recording. CI workflows lack documentation on how to provide key securely (GitHub secrets? Environment variable?). Document in Phase 1 as part of re-recording workflow. Verify cassette filtering works (`check_cassette_safety()` should catch leaked keys).

## Sources

### Primary (HIGH confidence)
- **ComptoxR codebase** (TODO.md, R/ct_*.R, dev/generate_stubs.R, tests/testthat/tools/) — actual bugs, working patterns, proven architecture
- [R Packages (2e)](https://r-pkgs.org/) — R package development standards (lifecycle, testing, documentation, R CMD check)
- [lifecycle package CRAN](https://cran.r-project.org/package=lifecycle) + [Lifecycle stages](https://lifecycle.r-lib.org/articles/stages.html) — badge types, protection patterns
- [vcr package documentation](https://docs.ropensci.org/vcr/) + [HTTP testing in R](https://books.ropensci.org/http-testing/) — cassette recording, management, quality checks
- [httr2 wrapping APIs guide](https://httr2.r-lib.org/articles/wrapping-apis.html) — API wrapper best practices, post-processing patterns
- [testthat package](https://testthat.r-lib.org/) — testing framework, parallel execution

### Secondary (MEDIUM confidence)
- [Tidy design principles](https://design.tidyverse.org/) — package design patterns (used to validate thin wrapper approach)
- [Managing cassettes | HTTP testing in R](https://books.ropensci.org/http-testing/managing-cassettes.html) — cassette naming, re-recording strategies
- [3 tips to tune your VCR in tests | Arkency Blog](https://blog.arkency.com/3-tips-to-tune-your-vcr-in-tests/) — cassette poisoning pitfalls, workflow best practices
- [Code generation in R packages - R-hub blog](https://blog.r-hub.io/2020/02/10/code-generation/) — validation of stub generation approach

### Tertiary (LOW confidence)
- [nycOpenData: A unified R interface to NYC Open Data APIs](https://www.r-bloggers.com/2026/01/nycopendata-a-unified-r-interface-to-nyc-open-data-apis/) — 2026 example of wrapper pattern (used to confirm thin wrapper is industry standard, not unique to ComptoxR)

---
*Research completed: 2026-03-04*
*Ready for roadmap: yes*
