# Phase 30: Build Quality Validation - Research

**Researched:** 2026-03-11
**Domain:** R package build validation and quality assurance
**Confidence:** HIGH

## Summary

Phase 30 focuses on achieving 0 errors from R CMD check while accepting existing warnings (doc line widths) and notes (cosmetic) as non-blocking. The primary technical work involves adding the yaml package to DESCRIPTION Imports and fixing a duplicate argument name in one bioactivity stub function.

R CMD check is R's comprehensive package validation system. It performs ~50 checks covering documentation, namespace consistency, code quality, example execution, and test execution. For CRAN submission, 0 errors and 0 warnings are required; notes are discouraged but sometimes acceptable with explanation. For internal packages, 0 errors is the critical threshold—warnings and notes may be acceptable depending on organizational policy.

The phase deliverable is code alignment: all fixes applied and ready for user verification. The user will execute devtools::check() and devtools::test() themselves to confirm success.

**Primary recommendation:** Add yaml to DESCRIPTION Imports (not Suggests) because the hook system (.onLoad calls load_hook_config()) requires it at package load time. Fix the duplicate endpoint argument in ct_bioactivity_assay_search_by_endpoint.R by renaming the formal parameter. Run devtools::document() to regenerate NAMESPACE and .Rd files. Lifecycle badge promotion is deferred (confirmed out of scope per CONTEXT.md).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- R CMD check target: 0 errors only (hard requirement)
- Warnings (doc line widths) and notes (cosmetic) are acceptable and left alone
- Byte-compile notes only fixed if they cause installation errors
- Add yaml to Imports in DESCRIPTION (not Suggests)—hook system is core functionality, no graceful fallback needed
- Fix duplicate endpoint argument only if R CMD check treats it as an error (not just a note)
- Verification approach: User will run tests and R CMD check themselves—phase deliverable is getting code lined up

### Claude's Discretion
- Whether to scan all generated stubs for similar argument-matching issues
- How to structure fixes (single plan vs multiple)
- Whether to run devtools::document() after DESCRIPTION changes

### Deferred Ideas (OUT OF SCOPE)
- Lifecycle promotion of user-facing functions to @lifecycle stable—future work
- Full test coverage audit of migrated functions—future work
- Fixing doc line width warnings—cosmetic, not blocking
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| devtools | Latest (2.4.5+) | Package development workflow | De facto standard for R package development, wraps R CMD check |
| roxygen2 | Latest (7.3.3+) | Documentation generation | Industry standard for @param/@export documentation |
| testthat | 3.0.0+ | Unit testing framework | Modern R testing standard (edition 3) |
| vcr | Latest | HTTP cassette testing | Standard for recording/replaying API responses |
| yaml | Latest | YAML parsing | Mature, stable parser for hook configuration |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| rcmdcheck | Latest | Programmatic R CMD check | CI/CD automation (optional for manual dev) |
| usethis | Latest | Package setup helpers | Lifecycle badge setup, DESCRIPTION editing |
| lifecycle | Latest | Deprecation badges | Marking function stability (@lifecycle stable, experimental) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| vcr | httptest2 | Would require rewriting 608 existing cassettes—not worth migration cost |
| testthat | RUnit/testit | Testthat edition 3 is modern standard with better reporter, snapshot testing |
| yaml | jsonlite | YAML is human-editable config format; hook_config.yml already written |

**Installation:**
```bash
# Already in DESCRIPTION—no additional installs needed
# yaml is the only missing piece (phase fixes this)
```

## Architecture Patterns

### R CMD Check Error Hierarchy
```
R CMD check priorities:
├── ERRORS     → Must fix (0 required for this phase)
├── WARNINGS   → Should fix for CRAN; optional for internal packages
└── NOTES      → Optional; CRAN reviewers scrutinize, but not blockers
```

**Pattern:** Fix errors first, evaluate warnings by impact (functionality vs cosmetic), accept notes unless causing real issues.

### DESCRIPTION Imports vs Suggests
```yaml
# Rule: Imports = runtime dependencies (always available)
#       Suggests = optional/dev-time dependencies (might not be installed)

Imports:
  - yaml              # Required by .onLoad—package won't load without it
  - httr2             # Required by generic_request—core functionality
  - dplyr             # Required by tidy transformations

Suggests:
  - testthat          # Only needed during devtools::test()
  - vcr               # Only needed during test execution
  - usethis           # Only needed for dev tasks (badge setup, etc.)
```

**Pattern:** If .onLoad, .onAttach, or exported functions call it directly, it belongs in Imports.

### Duplicate Formal Arguments Error
**What goes wrong:**
```r
# WRONG: parameter name matches argument name to generic_request()
ct_bioactivity_assay_search_by_endpoint <- function(endpoint) {
  result <- generic_request(
    endpoint = "bioactivity/assay/search/by-endpoint/",  # formal arg
    `endpoint` = endpoint  # actual arg—duplicate!
  )
}
```

**How to fix:**
```r
# CORRECT: rename formal parameter to avoid collision
ct_bioactivity_assay_search_by_endpoint <- function(endpoint_name) {
  result <- generic_request(
    endpoint = "bioactivity/assay/search/by-endpoint/",
    `endpoint` = endpoint_name  # now distinct
  )
}
```

**Pattern:** When a function parameter becomes a query-string argument (not the API endpoint path), rename the formal parameter to avoid collision with generic_request's endpoint argument.

### Documentation Generation After DESCRIPTION Changes
```r
# Standard workflow after editing DESCRIPTION:
devtools::document()  # Regenerates NAMESPACE and .Rd files
devtools::load_all()  # Reload package with new dependencies
devtools::check()     # Verify changes didn't break build
```

**Pattern:** Always run document() after DESCRIPTION changes—roxygen2 reads DESCRIPTION metadata when generating documentation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML parsing | Custom parser | yaml::read_yaml() | Edge cases: multiline strings, escape sequences, type coercion |
| R CMD check | Manual validation | devtools::check() | Runs ~50 checks: documentation, namespace, tests, examples, etc. |
| Cassette cleanup | Bash scripts | vcr helper functions | Already implemented in helper-vcr.R (delete_cassettes, check_cassette_safety) |
| Lifecycle badges | Manual markdown | lifecycle::badge() | Standardized SVGs, roxygen integration, CRAN-accepted format |

**Key insight:** R package tooling is mature and comprehensive—leverage devtools/roxygen2/usethis ecosystem rather than reinventing validation logic.

## Common Pitfalls

### Pitfall 1: Putting Runtime Dependencies in Suggests
**What goes wrong:** Package loads, .onLoad() tries to call yaml::read_yaml(), function not found, load fails with cryptic error.
**Why it happens:** DESCRIPTION Suggests means "might not be installed"—R doesn't guarantee availability.
**How to avoid:** If .onLoad, .onAttach, or exported functions use it, put it in Imports.
**Warning signs:** Error message "there is no package called 'yaml'" during library(ComptoxR).

### Pitfall 2: Fixing Warnings Before Errors
**What goes wrong:** Spend hours fixing doc line widths, R CMD check still fails due to duplicate argument error.
**Why it happens:** Errors block the build; warnings don't. Errors must be fixed first.
**How to avoid:** Run devtools::check(), read output top-to-bottom, address ERRORs before WARNINGs before NOTEs.
**Warning signs:** CI fails even after "fixing" multiple warnings.

### Pitfall 3: Not Running devtools::document() After DESCRIPTION Changes
**What goes wrong:** Add yaml to Imports, NAMESPACE doesn't update, R CMD check still complains about missing dependency.
**Why it happens:** roxygen2 generates NAMESPACE from DESCRIPTION + @export tags; manual DESCRIPTION edits don't auto-trigger regeneration.
**How to avoid:** Always run document() after editing DESCRIPTION, .Rbuildignore, or adding new dependencies.
**Warning signs:** "namespace does not match DESCRIPTION imports" check failure.

### Pitfall 4: Backtick-Quoting Arguments Hides Duplicate Errors Until Runtime
**What goes wrong:** Code with `` `endpoint` = endpoint`` syntax-checks fine, but R CMD check or byte-compiler flags it as error/warning.
**Why it happens:** Backtick quoting allows reserved words/duplicates in source, but formal argument matching still applies at call time.
**How to avoid:** Avoid naming function parameters the same as common argument names (endpoint, method, server, query).
**Warning signs:** "formal argument matched by multiple actual arguments" in R CMD check notes or byte-compilation warnings.

## Code Examples

Verified patterns from official sources:

### Adding Dependency to DESCRIPTION Imports
```r
# Source: https://r-pkgs.org/dependencies-in-practice.html
# DESCRIPTION file:

Imports:
    cli,
    dplyr (>= 1.1.4),
    glue,
    here,
    httr2,
    jsonlite (>= 1.8.8),
    lifecycle,
    magrittr (>= 2.0.3),
    purrr (>= 1.0.2),
    rlang,
    scales,
    stringi,
    stringr (>= 1.5.1),
    tibble,
    tidyr (>= 1.3.1),
    yaml                    # <-- ADD HERE (alphabetical order)
```

**Note:** No version constraint needed for yaml—package is stable and mature.

### Running R CMD Check Workflow
```r
# Source: https://r-pkgs.org/workflow101.html
# Iterative fix workflow:

devtools::check()  # Run full check (or Ctrl+Shift+E in RStudio)
# Read output, find first ERROR
# Fix the error in source code
devtools::document()  # If you changed documentation or DESCRIPTION
devtools::check()  # Repeat until 0 errors
```

### Fixing Duplicate Argument Names
```r
# Source: https://adv-r.hadley.nz/functions.html
# Before (ERROR):
my_function <- function(endpoint) {
  generic_request(endpoint = "path/", endpoint = endpoint)
  # formal argument "endpoint" matched by multiple actual arguments
}

# After (CORRECT):
my_function <- function(endpoint_name) {
  generic_request(endpoint = "path/", endpoint = endpoint_name)
  # Clear: endpoint is API path, endpoint_name is query value
}
```

### Lifecycle Badge Usage (Deferred, but documented for future)
```r
# Source: https://lifecycle.r-lib.org/reference/badge.html
#' My Function
#'
#' @description
#' `r lifecycle::badge("stable")`  # <-- Badge at top of description
#'
#' @param x Input parameter
#' @export
my_function <- function(x) { ... }

# Setup (one-time):
# usethis::use_lifecycle()  # Copies badge SVGs to man/figures/
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual R CMD check via terminal | devtools::check() in R | ~2015 (devtools matured) | Integrated workflow, better error reporting |
| DESCRIPTION Depends field | DESCRIPTION Imports field | R 3.0+ (2013) | Cleaner namespace, less masking conflicts |
| Partial argument matching in packages | Explicit full names required | CRAN policy tightened ~2018 | warnPartialMatchArgs enforced by default |
| lifecycle in Suggests | lifecycle in Depends (if using badges) | Changed to just use badge() at build time | No runtime dependency needed for badges |

**Deprecated/outdated:**
- **DESCRIPTION Depends for non-base packages:** Now reserved for R version constraints and base packages only
- **Partial argument name matching:** CRAN requires explicit full names; partial matching is warning-level in strict mode
- **lifecycle runtime dependency for badges:** lifecycle::badge() runs at roxygen build time, not package load time

## Open Questions

1. **Should we scan all generated stubs for similar duplicate argument issues?**
   - What we know: Only ct_bioactivity_assay_search_by_endpoint.R flagged in CONTEXT.md
   - What's unclear: Whether other stubs have same pattern (endpoint parameter passed as query arg)
   - Recommendation: Grep for pattern `endpoint.*endpoint` in R/ directory, fix all instances preemptively (prevents future errors)

2. **Will duplicate endpoint argument actually cause an ERROR or just a NOTE?**
   - What we know: User said "fix only if it causes an error"
   - What's unclear: R CMD check severity depends on byte-compilation strictness
   - Recommendation: Fix it anyway—it's ambiguous code and takes 30 seconds to fix

3. **Should we consolidate yaml dependency fix + duplicate arg fix into one plan or two?**
   - What we know: Both are small, independent changes
   - What's unclear: User preference for granularity
   - Recommendation: Single plan—both changes take < 5 minutes total, both are mechanical fixes

## Validation Architecture

> nyquist_validation is enabled in .planning/config.json — test framework required

### Test Framework
| Property | Value |
|----------|-------|
| Framework | testthat 3.0.0+ with vcr cassette support |
| Config file | tests/testthat/setup.R (vcr configuration) |
| Quick run command | `devtools::test()` |
| Full suite command | `"C:/Program Files/R/R-4.5.1/bin/Rscript.exe" -e "devtools::test()"` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| N/A | yaml dependency loads hook config | unit | `devtools::test_file("tests/testthat/test-hooks.R")` | ✅ (42 tests passing) |
| N/A | R CMD check produces 0 errors | integration | `devtools::check()` | ✅ (workflow tool, not test file) |
| N/A | Package loads cleanly | smoke | `devtools::load_all()` | ✅ (workflow tool, not test file) |

**Note:** Phase 30 has no explicit requirement IDs in REQUIREMENTS.md—it's about achieving build quality, not implementing features.

### Sampling Rate
- **Per task commit:** `devtools::load_all()` (smoke test—package loads)
- **Per wave merge:** `devtools::check()` (full validation)
- **Phase gate:** `devtools::check()` with 0 errors before marking phase complete

### Wave 0 Gaps
None—existing test infrastructure covers all validation needs. Hook tests already verify yaml loading. R CMD check workflow is dev-time tool, not a test file.

## Sources

### Primary (HIGH confidence)
- [R CMD check – R Packages (2e)](https://r-pkgs.org/R-CMD-check.html) - Error/warning/note hierarchy
- [Dependencies: In Practice – R Packages (2e)](https://r-pkgs.org/dependencies-in-practice.html) - Imports vs Suggests
- [Fundamental development workflows – R Packages (2e)](https://r-pkgs.org/workflow101.html) - devtools::check() and devtools::document() patterns
- [Functions | Advanced R](https://adv-r.hadley.nz/functions.html) - Formal argument matching rules
- [Lifecycle stages • lifecycle](https://lifecycle.r-lib.org/articles/stages.html) - Badge definitions and best practices
- [Package 'yaml' CRAN](https://cran.r-project.org/web/packages/yaml/yaml.pdf) - YAML parser documentation

### Secondary (MEDIUM confidence)
- [Getting started with vcr](https://docs.ropensci.org/vcr/articles/vcr.html) - Cassette management patterns
- [Managing cassettes | HTTP testing in R](https://books.ropensci.org/http-testing/managing-cassettes.html) - vcr best practices

### Tertiary (LOW confidence)
None—all findings verified with official R package development documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - devtools/roxygen2/testthat are documented de facto standards
- Architecture: HIGH - DESCRIPTION Imports rules and duplicate arg errors verified in R documentation
- Pitfalls: HIGH - Common issues documented in R Packages (2e) and Advanced R
- Lifecycle badges: MEDIUM - Deferred to future work, but official docs reviewed for completeness

**Research date:** 2026-03-11
**Valid until:** 2026-04-11 (30 days—R package tooling is stable)
