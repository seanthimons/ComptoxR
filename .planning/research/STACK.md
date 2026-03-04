# Technology Stack

**Project:** ComptoxR v2.2 Package Stabilization
**Researched:** 2026-03-04

## Executive Summary

ComptoxR v2.2 migrates remaining ct_* functions to use centralized request templates (`generic_request()` and `generic_chemi_request()`) while stabilizing the package with lifecycle badges and comprehensive testing. The existing stack already provides all core capabilities—no new framework dependencies are needed. The migration requires only leveraging existing R package development tools (lifecycle, testthat, vcr, roxygen2) that are already in DESCRIPTION.

**Key Finding:** This is a stabilization milestone, not a feature expansion. The stack is complete—we need workflow discipline, not new packages.

---

## Core Stack (Existing - No Changes)

All core dependencies are already in DESCRIPTION and functional.

### HTTP Client & Request Handling
| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| httr2 | 1.2.1 | HTTP client | Modern pipeable API with built-in retries, rate limiting, OAuth support. Successor to httr. |
| jsonlite | ≥ 1.8.8 | JSON parsing | Fast, reliable JSON handling. Industry standard for R. |

**Integration point:** `generic_request()` and `generic_chemi_request()` in `R/z_generic_request.R` already handle all HTTP operations. Migration requires zero changes to HTTP stack.

### Data Manipulation (Tidyverse)
| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| dplyr | ≥ 1.1.4 (CRAN: 1.2.0) | Data transformation | Table joins for `ct_bioactivity(annotate=TRUE)`, filtering, mutating post-processed results. |
| tidyr | ≥ 1.3.1 | Data reshaping | Unnesting list-columns, pivoting API responses. Used in post-processing patterns. |
| purrr | ≥ 1.0.2 | Functional programming | Mapping over batches, list operations in `ct_lists_all(coerce=TRUE)`. |
| tibble | (installed) | Data frames | Tidy tibble output via `safe_tidy_bind()`. |

**Integration point:** Post-processing wrappers like `ct_lists_all()` use dplyr/tidyr/purrr for transformations after calling generated stubs. Versions already meet requirements (dplyr 1.2.0 has `filter_out()`, `recode_values()` but not needed for migration).

### String Processing
| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| stringr | ≥ 1.5.1 | String operations | Splitting DTXSID strings (`ct_lists_all(coerce=TRUE)`), pattern matching. |
| stringi | (installed) | Unicode handling | Dependency of stringr, handles unicode normalization. |

**Integration point:** Used in post-processing patterns for string splitting, cleaning.

### Package Development
| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| roxygen2 | 7.3.3 | Documentation generation | Converts roxygen comments to .Rd files. Supports lifecycle badges via inline R (`r lifecycle::badge("stable")`). |
| devtools | 2.4.5 | Development workflow | Orchestrates `document()`, `check()`, `test()`, `install()`. Modular architecture delegates to pkgload, pkgbuild, rcmdcheck. |

**Integration point:** `devtools::document()` regenerates man/ files after adding lifecycle badges. No changes needed—workflow already established.

---

## Lifecycle Management (Existing - Active Use)

### lifecycle Package
| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| lifecycle | 1.0.5 | Function lifecycle badges | Standard tidyverse approach to signaling function stability. Already imported in DESCRIPTION. |

**Current usage:**
- 409 functions already have lifecycle badges (per grep count)
- `ct_hazard()`, `ct_lists_all()`, `ct_bioactivity()` marked `@lifecycle stable`
- Badge inserted via roxygen: `#' @description` then `#' ` `r lifecycle::badge("stable")`

**Migration pattern:**
```r
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Retrieves hazard data by DTXSID.
```

**Stages used in v2.2:**
- **stable**: User-facing ct_* functions after migration passes tests
- **experimental**: (implicit) Generated stubs (not user-facing, may change with schema updates)

**Protection mechanism:**
- Stub generator checks for lifecycle badges in roxygen comments
- Functions marked `stable` are NOT overwritten during regeneration
- Enables safe coexistence of stable wrappers and generated stubs

**Source:** [lifecycle package CRAN](https://cran.r-project.org/package=lifecycle), [Lifecycle stages documentation](https://lifecycle.r-lib.org/articles/stages.html)

---

## Testing Infrastructure (Existing - No Changes)

### Test Framework
| Technology | Current Version | Purpose | Why |
|------------|-----------------|---------|-----|
| testthat | 3.2.3 (CRAN: 3.3.2) | Unit testing | Industry standard. Parallel test execution via `Config/testthat/parallel: true`. |
| vcr | 2.1.0 | HTTP replay | Records API interactions to YAML cassettes. Works with httr, httr2, crul. No internet required after recording. |
| webmockr | (suggested) | HTTP mocking | Dependency of vcr. Provides request matching and replay. |

**Current test coverage:**
- 256 API wrapper functions
- 33 have VCR cassettes recorded
- 297 pre-existing test failures (VCR/API key issues)
- Test generator in `dev/generate_tests.R` creates metadata-aware tests

**VCR workflow (already established):**
1. First run: Requires API key, hits production, records to `tests/testthat/fixtures/*.yml`
2. Subsequent runs: Replays from cassettes (no API key needed)
3. CI runs: Use recorded cassettes (no live API calls)

**Cassette management helpers:**
```r
# In tests/testthat/helper-vcr.R
list_cassettes()                  # List all cassettes
delete_cassettes("ct_hazard*")    # Delete by pattern
check_cassette_safety()           # Verify no leaked API keys
check_cassette_errors(delete=TRUE) # Find/delete 4xx/5xx responses
```

**Integration point:** Migration tests use same VCR pattern as existing tests. No new testing patterns required.

**Sources:**
- [vcr package documentation](https://docs.ropensci.org/vcr/)
- [Using vcr • HTTP testing in R](https://books.ropensci.org/http-testing/vcr.html)
- [testthat 3.3.2 CRAN](https://cran.r-project.org/web/packages/testthat/testthat.pdf)

### Alternative: httptest2 (Evaluated - NOT Recommended)

| Technology | Version | Purpose | Why NOT |
|------------|---------|---------|---------|
| httptest2 | (available) | Alternative HTTP mocking | Would require rewriting 33+ existing cassettes. vcr already works with httr2. Migration cost > benefit. |

**Decision:** Stay with vcr. It already supports httr2, has 33 cassettes recorded, and provides cassette management helpers.

**Source:** [httptest2 documentation](https://enpiar.com/httptest2/articles/httptest2.html)

---

## Migration-Specific Patterns

### Pattern 1: Thin Wrapper (ct_hazard)
**Stack requirement:** None beyond generic_request()

```r
ct_hazard <- function(query) {
  ct_hazard_toxval_search_bulk(query = query)
}
```

**Testing:** Standard VCR cassette, expects tibble output.

### Pattern 2: Dispatcher with Post-Processing (ct_bioactivity)
**Stack requirement:** dplyr (already imported)

```r
ct_bioactivity <- function(query, search_type, annotate = FALSE) {
  df <- switch(search_type,
    "dtxsid" = ct_bioactivity_data_search_bulk(query),
    "aeid"   = ct_bioactivity_data_search_by_aeid_bulk(query),
    ...
  )

  if (annotate) {
    bioassay_all <- ct_bioactivity_assay()
    df <- dplyr::left_join(df, bioassay_all, by = "aeid")
  }

  return(df)
}
```

**Testing:** Multiple cassettes (one per search_type, one for annotate=TRUE). VCR can handle multiple cassettes per test file.

### Pattern 3: Conditional Post-Processing (ct_lists_all)
**Stack requirement:** dplyr, purrr, stringr (already imported)

```r
ct_lists_all <- function(return_dtxsid = FALSE, coerce = FALSE) {
  projection <- if (!return_dtxsid) "chemicallistall" else "chemicallistwithdtxsids"
  df <- ct_chemical_list_all(projection = projection)

  if (return_dtxsid & coerce) {
    df <- df %>%
      split(.$listName) %>%
      purrr::map(~ {
        .x$dtxsids <- stringr::str_split(.x$dtxsids, ",")[[1]]
        .x
      })
  }

  return(df)
}
```

**Testing:** Multiple cassettes for projection variants. Test coerce logic separately with pre-recorded data.

---

## What NOT to Add

### S7 Classes
**Status:** Deferred to post-v2.2 (#29)
**Why:** Migration focuses on function stabilization, not return type refactoring. S7 would require changing all return types, breaking user code.

### Post-Processing Recipe System
**Status:** Deferred (#120)
**Why:** Only 3-4 functions have complex post-processing (ct_bioactivity, ct_lists_all, ct_details). Recipe system is over-engineering until proven pattern emerges from more migrations.

### Advanced Schema Handling
**Status:** Deferred (ADV-01-04)
**Why:** Stub generation pipeline is complete and functional. Advanced features (nested schemas, $allOf, discriminators) not needed for current OpenAPI schemas.

### Parallel Page Fetching
**Status:** Out of scope
**Why:** EPA API rate limits make sequential safer. Pagination engine (v2.0) handles offset/limit, page/size, cursor, and path-based strategies sequentially.

### Session Caching
**Status:** Out of scope
**Why:** Separate concern. Package already uses `.ComptoxREnv` for compiled regex caching, but result caching belongs in user space.

---

## Installation

### Required (Already in DESCRIPTION)
```r
# Core dependencies (Imports)
install.packages(c(
  "httr2", "jsonlite",           # HTTP & JSON
  "dplyr", "tidyr", "purrr", "tibble", # Data manipulation
  "stringr", "stringi",           # String processing
  "cli", "lifecycle", "rlang",    # Package infrastructure
  "glue", "here", "magrittr", "scales" # Utilities
))

# Development dependencies (Suggests)
install.packages(c(
  "testthat", "vcr", "webmockr",  # Testing
  "roxygen2", "devtools",         # Documentation & workflow
  "mockery", "withr"              # Test utilities
))
```

### Version Constraints
- R (>= 3.5.0): Wide compatibility, no cutting-edge features required
- dplyr (>= 1.1.4): Need `across()`, `where()` selectors. Current CRAN (1.2.0) exceeds requirement.
- jsonlite (>= 1.8.8): Security and performance fixes
- stringr (>= 1.5.1): Improved regex handling
- tidyr (>= 1.3.1): Modern unnesting functions

**All constraints already satisfied by current CRAN versions.**

---

## Development Workflow (Unchanged)

### Documentation Regeneration
```r
devtools::document()  # Regenerate man/ from roxygen comments
```

Run after:
- Adding lifecycle badges to ct_* functions
- Migrating function to use generated stub
- Changing parameter signatures

### Testing
```r
devtools::test()                              # Run all tests
testthat::test_file("tests/testthat/test-ct_hazard.R")  # Run specific test

# VCR cassette management (first run requires API key)
source("tests/testthat/helper-vcr.R")
delete_cassettes("ct_hazard*")                # Re-record cassette
check_cassette_safety()                       # Verify no leaked keys
```

### Package Check
```r
devtools::check()  # R CMD check (comprehensive validation)
```

Target: 0 errors, 0 warnings before marking functions `stable`.

---

## Integration Points

### Stub Generator → User-Facing Wrappers
**File:** `dev/endpoint_eval/07_stub_generation.R`

**Lifecycle protection:**
```r
# Stub generator checks roxygen comments for lifecycle badges
# If badge == "stable", skip overwriting that function
# Allows safe regeneration without clobbering stable wrappers
```

**Migration workflow:**
1. Generate stub (e.g., `ct_hazard_toxval_search_bulk()`)
2. Create thin wrapper (`ct_hazard()`) that calls stub
3. Test wrapper with VCR
4. Add `@lifecycle stable` badge
5. Run `devtools::document()`
6. Future stub regeneration skips wrapper, regenerates underlying stub

### Test Generator → Migration Tests
**File:** `dev/generate_tests.R`

**Metadata extraction:**
- Reads function signatures via `extract_function_formals()`
- Detects `tidy` flag from `generic_request()` calls in function body
- Generates tests expecting tibble output if `tidy=TRUE`
- Handles static endpoints (no parameters) correctly

**Migration workflow:**
1. Migrate ct_* function to use stub
2. Run test generator: `source("dev/generate_tests.R")`
3. Record cassette on first test run (requires API key)
4. Subsequent runs replay cassette

### Generic Request Templates → All Functions
**File:** `R/z_generic_request.R`

**Already handles:**
- Batching (default: 200 items per POST)
- Authentication (x-api-key header)
- Retries (exponential backoff for 429/5xx)
- POST vs GET method selection
- Path parameters (`path_params` vector)
- Projection parameters
- Tidy conversion via `safe_tidy_bind()`

**No changes needed for migration.**

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| HTTP stack | HIGH | httr2 1.2.1 in production, generic_request() proven with 14 functions |
| Testing infrastructure | HIGH | vcr 2.1.0 supports httr2, 33 cassettes recorded, helper functions work |
| Lifecycle management | HIGH | lifecycle 1.0.5 stable, 409 functions already badged, stub generator protection works |
| Development workflow | HIGH | devtools 2.4.5, roxygen2 7.3.3 in daily use, R CMD check passes (v2.1) |
| Migration patterns | MEDIUM | Thin wrappers proven (ct_hazard), dispatcher patterns proven (ct_bioactivity), but 20+ functions untested |
| Post-processing complexity | MEDIUM | ct_lists_all pattern works, but edge cases may emerge in complex functions |

## Gaps & Risks

### Identified Gaps
1. **Test coverage:** Only 33/256 functions have VCR cassettes. Migration will require recording cassettes for 20+ functions.
2. **Undocumented post-processing patterns:** May discover new patterns beyond thin wrapper / dispatcher / conditional logic.
3. **Edge cases in generated stubs:** Some ct_* functions may expose bugs in stub generation (e.g., incorrect parameter mapping, missing pagination).

### Mitigation Strategies
1. **Test coverage:** Prioritize cassette recording for high-traffic functions first (hazard, bioactivity, lists). Batch recording sessions with API key set.
2. **Pattern discovery:** Document patterns as discovered in ARCHITECTURE.md (deferred to ARCHITECTURE research). Extract to recipe system only if 5+ functions share complex pattern.
3. **Stub edge cases:** Test-driven migration—if stub doesn't work, fix stub generator, regenerate, retest. Use lifecycle protection to avoid overwriting stable wrappers.

---

## Sources

**R Package Development:**
- [R Packages (2e)](https://r-pkgs.org/) — Comprehensive guide to package development
- [devtools package](https://devtools.r-lib.org/) — Development workflow tools
- [roxygen2 documentation](https://roxygen2.r-lib.org/) — In-line documentation system

**Lifecycle Management:**
- [lifecycle package CRAN](https://cran.r-project.org/package=lifecycle) — Official package page
- [Lifecycle stages](https://lifecycle.r-lib.org/articles/stages.html) — Badge types and usage
- [Lifecycle badges in roxygen](https://lifecycle.r-lib.org/reference/badge.html) — Embedding badges in documentation

**Testing & HTTP Mocking:**
- [testthat package](https://testthat.r-lib.org/) — Unit testing framework
- [vcr package documentation](https://docs.ropensci.org/vcr/) — HTTP replay library
- [Using vcr • HTTP testing in R](https://books.ropensci.org/http-testing/vcr.html) — VCR usage guide
- [httptest2 documentation](https://enpiar.com/httptest2/articles/httptest2.html) — Alternative HTTP mocking (not recommended)
- [httr2 wrapping APIs guide](https://httr2.r-lib.org/articles/wrapping-apis.html) — Best practices for API wrappers

**Package Versions:**
- [dplyr 1.2.0 release notes](https://tidyverse.org/blog/2026/02/dplyr-1-2-0/) — Latest dplyr features
- [purrr CRAN page](https://cran.r-project.org/web/packages/purrr/purrr.pdf) — Functional programming tools
- [cli package CRAN](https://cran.r-project.org/package=cli) — CLI helpers (version 3.6.4)

---

**Last Updated:** 2026-03-04
**Overall Confidence:** HIGH — Stack is complete and proven. Migration requires workflow discipline, not new dependencies.
