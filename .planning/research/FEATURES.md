# Feature Landscape

**Domain:** R Package Function Migration and API Wrapper Stabilization
**Researched:** 2026-03-04

## Table Stakes

Features users/maintainers expect. Missing = package feels incomplete or unstable.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| User-facing functions delegate to templates | Core architectural pattern for maintainability | Low | All ct_* functions should call generic_request() or generated stubs |
| Lifecycle badges on all exported functions | R package standard for stability signaling | Low | `lifecycle::badge("stable")` in roxygen2 docs; CRAN expectation |
| Consistent function signatures | User experience expectation | Low | All similar endpoints use same parameter names (e.g., `query`) |
| Batching handled transparently | API wrapper requirement | Low | Already implemented in generic_request(); users shouldn't manage chunks |
| Authentication handled automatically | API wrapper requirement | Low | Already implemented via ct_api_key() |
| VCR test cassettes for all functions | R API testing standard | Medium | Prevents hitting live API during tests; rOpenSci requirement |
| Error handling and validation | Production package requirement | Low | HTTP errors converted to informative R errors with helpful messages |
| Return type consistency | Tidy data ecosystem expectation | Low | All functions return tibbles (unless tidy=FALSE) |
| Roxygen documentation completeness | CRAN requirement | Low | All exported functions documented with @param, @return, @examples |
| R CMD check passes cleanly | CRAN submission requirement | Medium | 0 errors, 0 warnings on current branch |
| Phased deprecation when renaming | User code stability requirement | Low | experimental → stable → superseded → deprecated (not instant breaking changes) |
| Parameter validation | Prevents silent failures | Low | Check query types, validate match.arg() for enums |

## Differentiators

Features that set this package apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Automated stub generation from OpenAPI schemas | Reduces manual coding, ensures API parity | High | Already implemented in pipeline (v1.0-v2.1) |
| Thin wrapper layer pattern | User-friendly names + generated implementation | Low | ct_hazard() → ct_hazard_toxval_search_bulk() |
| Multi-endpoint dispatcher pattern | Single function for related endpoints | Medium | ct_bioactivity() with search_type switch; better UX than separate functions |
| Projection-aware wrappers | Fine-grained control of API response fields | Low | ct_details() with projection parameter; reduces bandwidth/noise |
| Post-processing layer pattern | Transform API responses for R workflows | Medium | ct_lists_all() with coerce/split logic; R-native data structures |
| Secondary annotation join pattern | Enrich data with related endpoints | Medium | ct_bioactivity(annotate=TRUE) joins assay details automatically |
| Auto-pagination engine | Transparent handling of paginated endpoints | High | Already implemented in generic_request() (v2.0); users get all data without loops |
| Metadata-driven test generation | Automatically creates correct tests from function signatures | Medium | Already implemented (v2.1); reads tidy flag, parameter types |
| Session-level caching | Performance optimization for expensive operations | Medium | .ComptoxREnv for pre-compiled regex/classifiers; speeds up repeated calls |
| Debug/verbose modes | Development and troubleshooting aid | Low | run_debug() / run_verbose() flags; helps users diagnose issues |
| Multiple server environment support | Development, staging, production switching | Low | ctx_server(1/2/3) for environment selection; supports EPA's multi-env setup |
| Lifecycle-protected stub regeneration | Prevents overwriting stable functions | Medium | #95 protection system; stable functions immune to generator runs |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Custom post-processing for every function | Creates maintenance burden, hard to test | Use generic_request() tidy conversion; only add custom post-processing when clear user need exists (#120 deferred) |
| Direct httr2 calls in user-facing functions | Duplicates batching/auth/error logic | Always delegate to generic_request() or generated stubs |
| Identical user-facing and generated function names | Confuses users, breaks API-to-package mapping | Use thin wrappers: ct_hazard() calls ct_hazard_toxval_search_bulk() |
| Complex multi-step migrations without notice | Breaks user code, creates churn | Use phased deprecation: experimental → stable → superseded → deprecated with clear warnings |
| Manual test fixture creation | Time-consuming, error-prone | Use VCR for HTTP recording, metadata-driven generator for test structure |
| Inline API key validation in each function | Code duplication, inconsistent errors | Centralize in ct_api_key() helper |
| Per-function batch limit configuration | Inconsistent UX, hard to document | Use global batch_limit() or Sys.getenv("batch_limit") |
| Overwriting stable functions during stub regeneration | Destroys user-facing API stability | Protect stable functions with lifecycle badges (#95) |
| Test-on-demand without cassettes | Rate limits, API dependency, slow CI | Record cassettes once, replay for subsequent runs |
| Parallel page fetching for pagination | Rate limits make sequential safer | Use httr2::req_perform_iterative() with sequential execution |
| Hardcoded default values duplicated across functions | Maintenance burden when API changes | Extract defaults to config; single source of truth |
| Synchronous function names across ct_* and generated stubs | Namespace pollution, confusing autocomplete | Keep user-facing names short (ct_hazard), generated names explicit (ct_hazard_toxval_search_bulk) |

## Feature Dependencies

```
Lifecycle badges → Stub generation protection (#95)
  ↓
User-facing wrappers → Generated stubs
  ↓
Generated stubs → generic_request()
  ↓
generic_request() → Batching + Auth + Error handling + Tidy conversion

VCR cassettes → Test generator
  ↓
Test generator → Metadata extraction from function signatures
  ↓
Metadata extraction → Correct test assertions (tidy flag, parameter types)

Post-processing wrappers → Secondary endpoint calls
  ↓
Secondary endpoint calls → Generated stubs or generic_request()

R CMD check passing → Lifecycle badges + Documentation + Valid examples
```

## Migration Pattern Taxonomy

Based on codebase analysis, user-facing function complexity falls into four categories:

### Pattern 1: Thin Delegation (Trivial)
**Example:** `ct_hazard()`, `ct_functional_use()`, `ct_demographic_exposure()`
**Complexity:** Low
**Effort:** 10 min/function
**Structure:** 1-line call to generated stub
```r
ct_hazard <- function(query) {
  ct_hazard_toxval_search_bulk(query = query)
}
```
**Migration steps:**
1. Verify generated stub exists and works
2. Add `lifecycle::badge("stable")` to roxygen
3. Add @param/@return/@examples documentation
4. Generate VCR test cassette
5. Run R CMD check

**Dependencies:** Generated stub must exist first

### Pattern 2: Direct Template Call (Simple)
**Example:** `ct_details()`, `ct_lists_all()` (base case without coerce)
**Complexity:** Low-Medium
**Effort:** 20 min/function
**Structure:** Direct call to generic_request() with endpoint-specific parameters
```r
ct_details <- function(query, projection = "compact") {
  generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-dtxsid/",
    method = "POST",
    projection = projection
  )
}
```
**Migration steps:**
1. Identify API endpoint from schema
2. Map parameters (query, projection, method)
3. Test projection values with live API
4. Add lifecycle badge + documentation
5. Generate VCR cassette
6. Run R CMD check

**Dependencies:** None (calls generic_request directly)

### Pattern 3: Multi-Endpoint Dispatcher (Complex)
**Example:** `ct_bioactivity()`
**Complexity:** Medium-High
**Effort:** 45 min/function
**Structure:** Switch/case dispatching to multiple generated stubs based on search_type
```r
ct_bioactivity <- function(
  query,
  search_type = c("dtxsid", "aeid", "spid", "m4id"),
  annotate = FALSE
) {
  search_type <- match.arg(search_type)
  df <- switch(
    search_type,
    "dtxsid" = ct_bioactivity_data_search_bulk(query = query),
    "aeid"   = ct_bioactivity_data_search_by_aeid_bulk(query = query),
    "spid"   = ct_bioactivity_data_search_by_spid_bulk(query = query),
    "m4id"   = ct_bioactivity_data_search_by_m4id_bulk(query = query)
  )
  if (annotate) {
    bioassay_all <- ct_bioactivity_assay()
    df <- dplyr::left_join(df, bioassay_all, by = "aeid")
  }
  return(df)
}
```
**Migration steps:**
1. Identify all related endpoints from schema
2. Map search_type values to generated stub names
3. Verify all generated stubs exist and work
4. Test annotation join logic (if applicable)
5. Test all search_type branches
6. Add lifecycle badge + documentation
7. Generate VCR cassettes for each branch
8. Run R CMD check

**Dependencies:** All dispatched-to stubs must exist

### Pattern 4: Post-Processing Transform (Complex)
**Example:** `ct_lists_all()` (with coerce=TRUE)
**Complexity:** Medium-High
**Effort:** 60 min/function
**Structure:** Conditional projection + data transformation
```r
ct_lists_all <- function(return_dtxsid = FALSE, coerce = FALSE) {
  projection <- if (!return_dtxsid) {
    "chemicallistall"
  } else {
    "chemicallistwithdtxsids"
  }

  df <- ct_chemical_list_all(projection = projection)

  cli::cli_alert_success("{nrow(df)} lists found!")

  if (return_dtxsid & coerce) {
    cli::cli_alert_warning("Coercing DTXSID strings per list to list-column!")
    df <- df %>%
      split(.$listName) %>%
      purrr::map(~ {
        .x$dtxsids <- stringr::str_split(.x$dtxsids, pattern = ",")[[1]]
        .x
      })
  } else if (!return_dtxsid & coerce) {
    cli::cli_alert_warning("You need to request DTXSIDs to coerce!")
  }

  return(df)
}
```
**Migration steps:**
1. Identify transformation logic
2. Map conditional projections to API parameters
3. Verify generated stub supports projection
4. Test with/without flags (all combinations)
5. Test edge cases (empty results, single list, 100+ lists)
6. Verify cli messages are informative
7. Add lifecycle badge + documentation
8. Generate VCR cassettes for all branches
9. Run R CMD check

**Dependencies:** Generated stub + projection support

## MVP Recommendation for v2.2

Prioritize (must-have for package stabilization):
1. **Lifecycle badges on all user-facing ct_* functions** - Table stakes, enables stub protection (#95), CRAN expectation
2. **R CMD check passes (0 errors/warnings)** - CRAN requirement, blocks release
3. **Pattern 1 (Thin Delegation) migration** - Low risk, high coverage (~60% of functions), 10 min each
4. **Pattern 2 (Direct Template) migration** - Medium risk, medium coverage (~20% of functions), 20 min each
5. **VCR cassettes for all migrated functions** - Testing requirement, prevents regressions
6. **Test generator handles all patterns** - Automation requirement, ensures consistency

Defer (post-v2.2):
- **Pattern 3 (Multi-Endpoint Dispatcher) migration** - Requires deeper testing strategy, ~10% of functions
- **Pattern 4 (Post-Processing) migration** - Requires design decisions about recipe system (#120), ~10% of functions
- **Advanced schema handling** (ADV-01-04) - Pipeline work, separate milestone
- **S7 class implementation** (#29) - Architectural change, separate milestone
- **Post-processing recipe system** (#120) - Wait for concrete user need from Pattern 4 migrations

## Complexity Assessment by Pattern

| Pattern | Functions Affected | Migration Effort | Testing Effort | Risk Level | Priority |
|---------|-------------------|------------------|----------------|------------|----------|
| Thin Delegation | ~60% of ct_* functions | 10 min/function | 5 min/function | Very Low | v2.2 ✓ |
| Direct Template | ~20% of ct_* functions | 20 min/function | 15 min/function | Low | v2.2 ✓ |
| Multi-Endpoint Dispatcher | ~10% of ct_* functions | 45 min/function | 30 min/function | Medium | v2.3 |
| Post-Processing Transform | ~10% of ct_* functions | 60 min/function | 45 min/function | High | v2.3+ |

**Total estimated effort for v2.2 (targeting Patterns 1-2 only):**
- Assuming 35 total functions, 80% coverage = 28 functions
- Pattern 1 (21 functions): 21 × 15 min = 5.25 hours
- Pattern 2 (7 functions): 7 × 35 min = 4 hours
- Lifecycle badges (all 28): 2 hours
- R CMD check iterations: 4 hours
- **Total: ~15 hours** (~2 days at 8 hours/day)

**Note:** This is significantly lower than previous 65-hour estimate because:
1. Generated stubs already exist (v1.0-v2.1 shipped)
2. VCR infrastructure already set up (v1.8)
3. Test generator already functional (v2.1)
4. Deferring complex patterns to v2.3

## Quality Gates for Migration

Each migrated function must pass:

1. **Signature validation:** Parameters match user expectations (not internal API names)
2. **Lifecycle badge:** Present and correct stage (likely "stable" for existing functions)
3. **Documentation:** @param, @return, @examples complete; examples run successfully
4. **VCR cassette:** Recorded, sanitized (no API keys), committed to git
5. **Test coverage:** Single input, batch input, error handling covered
6. **R CMD check:** No new errors/warnings introduced
7. **Backwards compatibility:** Existing user code still works (or clear deprecation path)

## Anti-Pattern Checklist

Before marking function as "migrated," verify it does NOT:

- [ ] Duplicate batching logic (should delegate to generic_request or stub)
- [ ] Duplicate auth logic (should use ct_api_key() indirectly)
- [ ] Hardcode API endpoint URLs (should use server environment variables)
- [ ] Return inconsistent types (should always return tibble or list, not mixed)
- [ ] Swallow errors silently (should let HTTP errors bubble up with context)
- [ ] Have undocumented parameters (all @param must be present)
- [ ] Have missing examples (even if \dontrun{}, show usage)
- [ ] Lack lifecycle badge (required for stub protection #95)

## Sources

### R Package Standards and Best Practices
- [R Packages (2e): Lifecycle](https://r-pkgs.org/lifecycle.html) - Lifecycle stage definitions and transitions
- [lifecycle: Manage the Life Cycle of your Package Functions](https://lifecycle.r-lib.org/index.html) - Official package documentation
- [Lifecycle stages](https://lifecycle.r-lib.org/articles/stages.html) - Experimental, stable, superseded, deprecated stages
- [Package 'lifecycle' January 8, 2026](https://cran.r-project.org/web/packages/lifecycle/lifecycle.pdf) - Latest CRAN package documentation with 2026 updates
- [Deprecate functions and arguments](https://lifecycle.r-lib.org/reference/deprecate_soft.html) - Phased deprecation patterns
- [Communicate lifecycle changes](https://cran.r-project.org/web/packages/lifecycle/vignettes/communicate.html) - How to signal changes to users
- [Embed a lifecycle badge in documentation](https://lifecycle.r-lib.org/reference/badge.html) - Badge usage in roxygen2

### API Wrapper Patterns
- [Wrapping APIs • httr2](https://httr2.r-lib.org/articles/wrapping-apis.html) - Official httr2 API wrapper guide with post-processing patterns
- [httr2 1.0.0 - Tidyverse](https://tidyverse.org/blog/2023/11/httr2-1-0-0/) - Modern pipe-based interface and tibble conversion
- [Tidy design principles](https://design.tidyverse.org/) - Design patterns for R packages
- [How to Build an API wrapper package in 10 minutes](https://colinfay.me/build-api-wrapper-package-r/) - Practical API wrapper patterns
- [Code generation in R packages - R-hub blog](https://blog.r-hub.io/2020/02/10/code-generation/) - Code generation use cases for web APIs
- [nycOpenData: A unified R interface to NYC Open Data APIs](https://www.r-bloggers.com/2026/01/nycopendata-a-unified-r-interface-to-nyc-open-data-apis/) - 2026 example of wrapper pattern with shared design

### Testing Infrastructure
- [Getting started with vcr](https://docs.ropensci.org/vcr/articles/vcr.html) - VCR cassette recording/replay patterns
- [Chapter 6 Use vcr (& webmockr) | HTTP testing in R](https://books.ropensci.org/http-testing/vcr.html) - Comprehensive VCR testing guide
- [Chapter 30 Managing cassettes | HTTP testing in R](https://books.ropensci.org/http-testing/managing-cassettes.html) - Cassette management best practices: run tests twice (record + replay)
- [3 tips to tune your VCR in tests | Arkency Blog](https://blog.arkency.com/3-tips-to-tune-your-vcr-in-tests/) - Best practices: unique cassettes per test, body_json matcher

### Migration and Stabilization
- [Sustainable API migration with the S*T*A*R pattern | MuleSoft Blog](https://blogs.mulesoft.com/dev-guides/api-migration-star-pattern/) - Stabilize, Transform, Add, Repeat pattern
- [API as a package: Testing](https://www.jumpingrivers.com/blog/api-as-a-package-testing/) - API-as-package architecture patterns
- [R Packages - Function documentation](https://r-pkgs.org/man.html) - Roxygen2 documentation standards
- [R Packages - R code](https://r-pkgs.org/code.html) - Code organization and structure

### R Package Development
- [R Packages (2e): Data](https://r-pkgs.org/data.html) - Package data management
- [Wrapping in R :: dynverse](https://dynverse.org/developers/creating-ti-method/create_ti_method_r/) - Wrapper patterns for method packages
- [Design Patterns in R • Design Patterns in R](https://tidylab.github.io/R6P/) - General design patterns
