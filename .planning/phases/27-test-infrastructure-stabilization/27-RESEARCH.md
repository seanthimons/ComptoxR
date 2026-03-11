# Phase 27: Test Infrastructure Stabilization - Research

**Researched:** 2026-03-09
**Domain:** R package testing infrastructure (VCR cassettes, NAMESPACE management, parallel recording)
**Confidence:** HIGH

## Summary

This phase fixes mechanical blockers preventing reliable test execution: VCR key sanitization gaps, deprecated purrr::flatten warnings, and the need to re-record 717 cassettes with production API data. Research confirms all necessary tools exist (mirai 2.6.0, existing helper functions, parallel recording script template), standard patterns are well-established (NAMESPACE @importFrom, VCR filter_sensitive_data, mirai daemons), and the approach is straightforward infrastructure maintenance rather than novel development.

**Primary recommendation:** Execute in three waves - (1) fix NAMESPACE imports to eliminate warnings, (2) audit/enhance VCR sanitization, (3) re-record cassettes in parallel using mirai with major-family grouping and failure threshold halts.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Cassette Re-recording Strategy:**
- Record ALL 717 cassettes (full coverage, not a subset)
- Single R process using mirai package for async + parallel execution
- mirai::daemons() with mirai_map() over cassettes grouped by major family
- Parallel streams at the major family level (bioactivity, chemical, exposure, hazard, etc.)
- Halt on failure threshold - if failure rate exceeds threshold, stop the run
- Fire-and-forget design - user kicks it off and does other work

**Script Location:**
- Re-recording script: dev/record_cassettes.R
- Health check script: dev/check_cassette_health.R
- Both in dev/ alongside existing scripts
- NOT in tests/ or R/

**Success Threshold:**
- Zero mechanical failures - all VCR/auth/infrastructure failures eliminated
- Infrastructure-only verification - whether test assertions pass is Phase 28-30 territory
- Automated check validates: cassette safety (no leaked keys), no HTTP error responses frozen in fixtures, all fixture files parse without VCR errors

**VCR Sanitization:**
- Primary: x-api-key header filtering (already exists in helper-vcr.R)
- Additional: known internal/staging EPA URL patterns in response bodies (user will provide at planning time)
- Response body data is public EPA data - no PII concerns
- Cheminformatics endpoints are unauthenticated (auth=FALSE) - no key filtering needed for those

**NAMESPACE / Flatten Warning Fix:**
- Root cause: blanket @import purrr and @import jsonlite pull in deprecated purrr::flatten family
- Fix: replace with selective @importFrom declarations for functions actually used
- Source code: keep bare function calls (map() not purrr::map()) - fix NAMESPACE only, minimize file churn
- Both purrr and jsonlite need this treatment

### Claude's Discretion

- Exact mirai daemon count and rate limiting per family
- Failure threshold percentage (e.g., 10% vs 20%)
- Internal structure of the recording script (how it discovers cassette-to-function mappings)
- How to detect which cassettes belong to which major family (filename convention vs test file parsing)

### Deferred Ideas (OUT OF SCOPE)

None - discussion stayed within phase scope
</user_constraints>

## Standard Stack

### Core Testing Infrastructure
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| vcr | 2.1.0 | HTTP cassette recording/replay | ropensci standard for R API testing, YAML format, filter_sensitive_data support |
| testthat | 3.x | Test framework | R package testing de facto standard, edition 3 features |
| mirai | 2.6.0 | Async parallel execution | Modern R parallelization, microsecond dispatch overhead, hub architecture |
| httr2 | 1.x | HTTP client | Modern successor to httr, built-in exponential backoff for rate limits |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| fs | latest | File operations | Cross-platform path handling, directory listing |
| cli | latest | User messaging | Progress bars, formatted output, consistent with project patterns |
| here | latest | Path resolution | Portable path construction |
| purrr | 1.2.1 | Functional programming | Iteration patterns (note: flatten family deprecated) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| mirai | future | future is more mature but slower dispatch; mirai has microsecond overhead |
| vcr | httptest2 | Would require rewriting 717 cassettes; vcr working and established |
| parallel (base R) | foreach | foreach adds dependency; parallel less ergonomic than mirai |

**Installation:**
```bash
# All dependencies already installed in project
# mirai confirmed available: 2.6.0
```

## Architecture Patterns

### VCR Cassette Organization
Current structure (717 cassettes):
```
tests/testthat/fixtures/
├── _vcr/                    # VCR metadata
├── ct_bioactivity_*.yml     # CompTox bioactivity endpoints
├── ct_chemical_*.yml        # CompTox chemical endpoints
├── ct_exposure_*.yml        # CompTox exposure endpoints
├── ct_hazard_*.yml          # CompTox hazard endpoints
├── chemi_amos_*.yml         # Cheminformatics AMOS
├── chemi_resolver_*.yml     # Cheminformatics resolver
├── chemi_search_*.yml       # Cheminformatics search
└── chemi_*_*.yml           # Other chemi families
```

**Naming convention:** `{super_family}_{major_family}_{group}_{variant}.yml`
- super_family: ct (CompTox Dashboard) or chemi (Cheminformatics)
- major_family: bioactivity, chemical, exposure, hazard, amos, resolver, search, etc.
- group: specific endpoint group (analyticalqc, aop, assay, etc.)
- variant: single, batch, error, example, basic

### Pattern 1: VCR Cassette Recording with Sanitization
**What:** Record HTTP interactions to YAML files with sensitive data filtered
**When to use:** First test run or when API responses need updating
**Example:**
```r
# Source: https://docs.ropensci.org/vcr/articles/vcr.html
# In tests/testthat/helper-vcr.R
vcr::vcr_configure(
  dir = "../testthat/fixtures",
  filter_sensitive_data = list(
    "<<<API_KEY>>>" = Sys.getenv("ctx_api_key")
  )
)

# In test file
test_that("function works", {
  vcr::use_cassette("cassette_name", {
    result <- ct_function("DTXSID7020182")
    expect_type(result, "list")
  })
})
```

### Pattern 2: Parallel Cassette Recording with mirai
**What:** Use mirai daemons to record multiple cassettes concurrently with family-level grouping
**When to use:** Bulk re-recording of cassettes (Phase 27 use case)
**Example:**
```r
# Source: https://mirai.r-lib.org/
library(mirai)

# Initialize daemon pool
daemons(n = 8)

# Submit tasks
results <- mirai_map(
  test_files,
  function(file) {
    testthat::test_file(file, reporter = "minimal")
  }
)

# Cleanup
daemons(0)
```

### Pattern 3: NAMESPACE Import Hygiene
**What:** Use @importFrom for specific functions instead of blanket @import
**When to use:** Always - prevents namespace pollution and deprecation warnings
**Example:**
```r
# Source: https://roxygen2.r-lib.org/articles/namespace.html
# BAD (current state in R/ComptoxR-package.R)
#' @import purrr
#' @import jsonlite

# GOOD (target state)
#' @importFrom purrr map map2 walk imap compact pluck
#' @importFrom purrr list_flatten list_c list_rbind
#' @importFrom jsonlite fromJSON toJSON
```

Keep source code unchanged - R functions continue using bare `map()`, but NAMESPACE declares imports explicitly. Use `devtools::document()` to regenerate NAMESPACE after roxygen changes.

### Pattern 4: Cassette Health Checking
**What:** Programmatic validation of cassette integrity and security
**When to use:** Before committing cassettes, after re-recording
**Example:**
```r
# Source: existing helper-vcr.R (Phase 24)
# Check for leaked API keys
check_cassette_safety()

# Find cassettes with HTTP error responses
check_cassette_errors(delete = FALSE)

# List all cassettes
all_cassettes <- list_cassettes()
```

### Anti-Patterns to Avoid

- **Recording cassettes without API key validation:** Results in 401/403 error responses frozen in cassettes, causing permanent test failures
- **Committing unfiltered cassettes:** Leaks API keys to repository; always run check_cassette_safety() before git add
- **Blanket @import for packages with deprecated functions:** Triggers warnings on package load; use selective @importFrom
- **Serial cassette recording:** 717 cassettes * ~2 seconds = 24 minutes minimum; parallel recording with mirai reduces to <5 minutes
- **No failure threshold:** A single API outage or expired key causes 717 failed recordings; halt early on systemic issues

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Parallel R execution | Manual fork/socket clusters | mirai::daemons() | Microsecond dispatch overhead, automatic load balancing, hub architecture |
| HTTP retry logic | Custom exponential backoff | httr2 built-in | Handles 429 rate limits automatically, configurable via req_retry() |
| Path construction | paste/file.path with conditionals | here::here() | Portable across Windows/Unix, relative to project root |
| Cassette naming patterns | String concatenation | Existing test generator | Already handles single/batch/error/example variants consistently |
| Progress reporting | cat/message loops | cli package | Professional output, consistent with project patterns, progress bars |

**Key insight:** The tools for this phase already exist in the project or R ecosystem - this is assembly and configuration work, not greenfield development.

## Common Pitfalls

### Pitfall 1: Deprecated purrr::flatten Masking
**What goes wrong:** Package load triggers "purrr::flatten() is deprecated" warnings even though code uses list_flatten()
**Why it happens:** @import purrr in NAMESPACE pulls ALL purrr exports including deprecated flatten family, which then mask list_flatten()
**How to avoid:** Replace @import with explicit @importFrom declarations for only the functions actually used
**Warning signs:**
```
Warning: `flatten()` was deprecated in purrr 1.0.0.
Please use `list_flatten()` instead.
```
**Detection:** Current code (grep confirmed) uses 58 purrr:: calls across 21 files, primarily list_flatten, list_c, list_rbind, map variants

### Pitfall 2: VCR Recording Without API Key
**What goes wrong:** Tests run, cassettes record, but contain 401/403 error responses instead of data
**Why it happens:** VCR records whatever HTTP response occurs; if API key is missing, it records the authentication error
**How to avoid:** Pre-flight check validates ctx_api_key exists before starting recording process
**Warning signs:**
- Tests pass on first run (using cassettes) but would fail without cassettes
- Cassette YAML shows `status: 401` or `status: 403`
- Response body contains "Unauthorized" or "API key required"
**Detection:** Use check_cassette_errors() helper (Phase 24) to scan for non-2xx status codes

### Pitfall 3: Rate Limit Cascade Failure
**What goes wrong:** Parallel recording hits EPA API rate limits, all workers receive 429 responses, entire batch fails
**Why it happens:** 8 workers * multiple families * high request rate exceeds API quota
**How to avoid:**
- Family-level grouping naturally throttles (one family at a time, not all endpoints simultaneously)
- httr2's exponential backoff handles 429 automatically
- Failure threshold halts recording if >X% fail (likely indicates systemic issue not transient errors)
**Warning signs:** Multiple cassettes show `status: 429`, sudden spike in failed recordings across different families
**Detection:** Monitor failure rate during recording; if >10-20% fail, halt and investigate

### Pitfall 4: Internal EPA URLs in Response Bodies
**What goes wrong:** Cassettes contain internal-only URLs (staging servers, VPN-only endpoints) that fail when replayed in CI or by external contributors
**Why it happens:** Production API may return links to internal resources in response metadata
**How to avoid:** Add EPA internal URL patterns to vcr_configure filter_sensitive_data (user will provide patterns during planning)
**Warning signs:** Cassettes contain URLs with .epa.gov subdomains that aren't publicly accessible, tests pass locally but fail in CI
**Detection:** Grep cassettes for known internal patterns; health check script can automate this

### Pitfall 5: Cassette Filename Collisions
**What goes wrong:** Different test variants (single vs batch) overwrite each other's cassettes
**Why it happens:** VCR cassette names must be unique; if two tests use the same cassette name, second overwrites first
**How to avoid:** Existing test generator already handles this - uses function_variant pattern (e.g., ct_hazard_single, ct_hazard_batch)
**Warning signs:** Cassettes get unexpectedly overwritten during test runs, tests pass individually but fail when run together
**Detection:** Check for duplicate use_cassette() names across test files

## Code Examples

Verified patterns from official sources and project files:

### VCR Configuration with Multiple Filters
```r
# Source: tests/testthat/helper-vcr.R (Phase 24, verified)
library(vcr)

vcr_dir <- "../testthat/fixtures"
if (!dir.exists(vcr_dir)) dir.create(vcr_dir, recursive = TRUE)

vcr::vcr_configure(
  dir = vcr_dir,
  filter_sensitive_data = list(
    "<<<API_KEY>>>" = Sys.getenv("ctx_api_key"),
    # Add EPA internal URL filtering (user will provide patterns)
    "<<<INTERNAL_URL>>>" = "https://internal.epa.gov"
  )
)
```

### Parallel Cassette Recording with Failure Threshold
```r
# Source: dev/rerecord_cassettes.R (Phase 24, adapted for family grouping)
library(mirai)
library(cli)

# Configuration
N_WORKERS <- 8
FAILURE_THRESHOLD <- 0.15  # Halt if >15% fail

# Major families derived from cassette naming
MAJOR_FAMILIES <- c(
  "ct_bioactivity",
  "ct_chemical",
  "ct_exposure",
  "ct_hazard",
  "chemi_amos",
  "chemi_resolver",
  "chemi_search",
  "chemi_safety"
)

# Pre-flight check
if (!nzchar(Sys.getenv("ctx_api_key"))) {
  cli_abort("ctx_api_key not set. Request key from ccte_api@epa.gov")
}

# Initialize daemon pool
daemons(n = N_WORKERS)

# Process by family
for (family in MAJOR_FAMILIES) {
  cli_alert_info("Recording family: {family}")

  # Get cassettes for this family
  cassettes <- list.files("tests/testthat/fixtures",
                         pattern = paste0("^", family),
                         full.names = TRUE)

  if (length(cassettes) == 0) next

  # Submit parallel tasks
  results <- mirai_map(cassettes, function(cassette) {
    tryCatch({
      # Delete old cassette
      unlink(cassette)

      # Find corresponding test file
      test_file <- find_test_for_cassette(cassette)

      # Run test (records new cassette)
      testthat::test_file(test_file, reporter = "minimal")

      list(success = TRUE, cassette = cassette)
    }, error = function(e) {
      list(success = FALSE, cassette = cassette, error = e$message)
    })
  })

  # Check failure rate
  failures <- sum(!sapply(results, function(r) r$success))
  failure_rate <- failures / length(results)

  if (failure_rate > FAILURE_THRESHOLD) {
    cli_alert_danger("Failure rate {round(failure_rate * 100)}% exceeds threshold")
    cli_alert_warning("Halting - likely systemic issue (expired key, API outage)")
    break
  }

  cli_alert_success("Family complete: {failures} failures of {length(results)}")
}

# Cleanup
daemons(0)
```

### NAMESPACE Import Audit and Fix
```r
# Source: https://roxygen2.r-lib.org/articles/namespace.html
# Step 1: Audit actual usage (run from package root)
library(stringr)

# Find all purrr:: calls
purrr_calls <- system("grep -rh 'purrr::' R/ | grep -oE 'purrr::[a-z_]+' | sort -u",
                      intern = TRUE)
print(purrr_calls)
# Output: map, map2, walk, imap, compact, pluck, list_flatten, list_c, list_rbind

# Find all jsonlite:: calls
jsonlite_calls <- system("grep -rh 'jsonlite::' R/ | grep -oE 'jsonlite::[a-z_]+' | sort -u",
                        intern = TRUE)
print(jsonlite_calls)
# Output: fromJSON, toJSON, flatten (this one is the problem!)

# Step 2: Update R/ComptoxR-package.R
# Replace:
#   #' @import purrr
#   #' @import jsonlite
# With:
#   #' @importFrom purrr map map2 walk imap compact pluck
#   #' @importFrom purrr list_flatten list_c list_rbind
#   #' @importFrom jsonlite fromJSON toJSON

# Step 3: Regenerate NAMESPACE
devtools::document()

# Step 4: Verify warnings gone
devtools::load_all()
```

### Cassette Health Check Script
```r
# Source: dev/check_cassette_health.R (new file, this phase)
#!/usr/bin/env Rscript
# Check cassette health: safety, errors, parse validity

library(cli)
source("tests/testthat/helper-vcr.R")

cli_h1("VCR Cassette Health Check")

# Check 1: API key leaks
cli_h2("Checking for API key leaks")
safety_issues <- check_cassette_safety()

# Check 2: HTTP error responses
cli_h2("Checking for HTTP error responses")
error_cassettes <- check_cassette_errors(delete = FALSE)

# Check 3: Parse validity (can YAML be read?)
cli_h2("Checking YAML parse validity")
cassettes <- list.files("tests/testthat/fixtures",
                       pattern = "\\.yml$",
                       full.names = TRUE)

parse_errors <- list()
for (cassette in cassettes) {
  tryCatch({
    yaml::read_yaml(cassette)
  }, error = function(e) {
    parse_errors[[basename(cassette)]] <<- e$message
  })
}

if (length(parse_errors) > 0) {
  cli_alert_danger("Found {length(parse_errors)} cassettes with parse errors")
  for (name in names(parse_errors)) {
    cli_alert_warning("{name}: {parse_errors[[name]]}")
  }
} else {
  cli_alert_success("All cassettes parse successfully")
}

# Summary
cli_rule()
total_cassettes <- length(cassettes)
cli_alert_info("Total cassettes: {total_cassettes}")
cli_alert_info("Safety issues: {length(safety_issues)}")
cli_alert_info("Error responses: {nrow(error_cassettes)}")
cli_alert_info("Parse errors: {length(parse_errors)}")

if (length(safety_issues) == 0 &&
    nrow(error_cassettes) == 0 &&
    length(parse_errors) == 0) {
  cli_alert_success("All health checks passed!")
  quit(status = 0)
} else {
  cli_alert_danger("Health checks failed - review issues above")
  quit(status = 1)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| purrr::flatten() | purrr::list_flatten() | purrr 1.0.0 (2022) | Deprecated warnings on package load |
| @import for all packages | @importFrom selective imports | Ongoing best practice | Cleaner NAMESPACE, avoids deprecation warnings |
| Serial test recording | Parallel with mirai | mirai 2.6.0 (2026) | Microsecond dispatch, 5x faster recording |
| Manual cassette audit | Automated health checks | Phase 24 (2026-02) | Programmatic safety validation |

**Deprecated/outdated:**
- purrr::flatten() family: superseded by list_flatten(), list_c(), list_rbind()
- Blanket @import: causes namespace pollution, better to use @importFrom
- httr (v1): replaced by httr2 with built-in retry/backoff

## Open Questions

1. **EPA Internal URL Patterns for Filtering**
   - What we know: User will provide specific patterns at planning time
   - What's unclear: Exact regex patterns to filter EPA internal URLs in response bodies
   - Recommendation: Add placeholder in vcr_configure, user fills during planning wave setup

2. **Optimal Failure Threshold Percentage**
   - What we know: Need to halt on systemic failures (expired key, API outage)
   - What's unclear: Is 10% too sensitive? 20% too permissive?
   - Recommendation: Start at 15%, tune based on first recording run

3. **Cassette-to-Test-File Mapping Strategy**
   - What we know: Cassette names follow pattern `{function}_{variant}.yml`
   - What's unclear: Test files may have multiple cassettes; need reverse lookup function
   - Recommendation: Use filename pattern matching (test-ct_hazard.R contains ct_hazard_* cassettes)

4. **Recording Time Estimate**
   - What we know: 717 cassettes, parallel execution with 8 workers
   - What's unclear: Actual wall-clock time (depends on API response times, rate limits)
   - Recommendation: Expect 10-20 minutes for full recording, provide progress reporting

## Validation Architecture

> nyquist_validation: true (from .planning/config.json)

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.x |
| Config file | tests/testthat.R (existing) |
| Quick run command | `devtools::test()` |
| Full suite command | `devtools::test()` |

### Phase Requirements → Test Map

Phase 27 has no explicit requirement IDs from REQUIREMENTS.md (v2.2 milestone not yet defined there). Derived requirements from phase goal:

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INFRA-27-01 | NAMESPACE has no @import purrr or jsonlite | unit | Manual inspection of NAMESPACE | ✅ existing |
| INFRA-27-02 | Package loads without purrr deprecation warnings | smoke | `Rscript -e "library(ComptoxR)"` | ❌ Wave 0 |
| INFRA-27-03 | VCR filter includes x-api-key and EPA URL patterns | unit | Manual inspection of helper-vcr.R | ✅ existing |
| INFRA-27-04 | All cassettes pass safety check (no leaked keys) | integration | `Rscript dev/check_cassette_health.R` | ❌ Wave 0 |
| INFRA-27-05 | All cassettes have 2xx status codes | integration | `Rscript dev/check_cassette_health.R` | ❌ Wave 0 |
| INFRA-27-06 | All cassettes parse as valid YAML | integration | `Rscript dev/check_cassette_health.R` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Quick smoke test (`Rscript -e "library(ComptoxR)"`) - must load without warnings
- **Per wave merge:** Full health check (`Rscript dev/check_cassette_health.R`) - all cassettes valid
- **Phase gate:** Full test suite (`devtools::test()`) - must pass with recorded cassettes

### Wave 0 Gaps
- [ ] `dev/check_cassette_health.R` - covers INFRA-27-04, 05, 06 (automated health validation)
- [ ] Smoke test wrapper script - covers INFRA-27-02 (package load without warnings)

*(Existing test infrastructure from Phase 24 covers VCR helpers, existing devtools::document() handles NAMESPACE generation)*

## Sources

### Primary (HIGH confidence)
- R vcr package documentation (version 2.1.0, December 2025) - [Getting started with vcr](https://docs.ropensci.org/vcr/articles/vcr.html), [CRAN package page](https://cran.r-project.org/web/packages/vcr/vcr.pdf)
- R mirai package documentation (version 2.6.0, February 2026) - [Minimalist Async Evaluation Framework](https://mirai.r-lib.org/), [Quick Reference](https://cran.r-project.org/web/packages/mirai/vignettes/mirai.html)
- purrr 1.2.1 migration guide - [Flatten functions documentation](https://purrr.tidyverse.org/reference/flatten.html), [list_flatten reference](https://purrr.tidyverse.org/reference/list_flatten.html)
- roxygen2 namespace management - [Managing imports and exports](https://roxygen2.r-lib.org/articles/namespace.html)
- Project Phase 24 summaries (VCR cassette cleanup, parallel recording script) - verified against actual files

### Secondary (MEDIUM confidence)
- HTTP testing in R book (ropensci) - [Chapter 22 Caching HTTP requests](https://books.ropensci.org/http-testing/vcr-intro.html), [Chapter 30 Managing cassettes](https://books.ropensci.org/http-testing/managing-cassettes.html)
- API testing best practices (2026) - [API package best practices](https://cran.r-project.org/web/packages/crul/vignettes/best-practices-api-packages.html)
- R Packages book (2e) - [Dependencies in Practice](https://r-pkgs.org/dependencies-in-practice.html)

### Tertiary (LOW confidence)
- None - all findings verified with official documentation or project files

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all packages installed and versions verified
- Architecture: HIGH - patterns proven in Phase 24, mirai 2.6.0 released Feb 2026
- Pitfalls: HIGH - based on actual project code inspection and official deprecation warnings
- Validation: MEDIUM - health check script is new, but based on existing helper functions

**Research date:** 2026-03-09
**Valid until:** 60 days (stable dependencies, established patterns)
