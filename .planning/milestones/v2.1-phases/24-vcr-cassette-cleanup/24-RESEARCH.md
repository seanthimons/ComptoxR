# Phase 24: VCR Cassette Cleanup - Research

**Researched:** 2026-02-27
**Domain:** VCR cassette management, parallel re-recording, API key security auditing
**Confidence:** HIGH

## Summary

Phase 24 focuses on cleaning up VCR cassette infrastructure after Phase 23's test generator fixes. The phase involves deleting 673 untracked cassettes with incorrect parameters, building helper functions for cassette management, verifying API key filtering, and implementing a batched re-recording system using mirai for parallel execution. The R ecosystem has mature tooling for all requirements: vcr 2.1.0 provides filter_sensitive_data for API key filtering and built-in cassette management, mirai 2.6.0 offers efficient parallel execution with minimal dispatch overhead, and httr2's req_retry provides automatic exponential backoff for rate limiting. The project already uses all these libraries and has working patterns for batched API requests in generic_request().

**Primary recommendation:** Build helper functions in tests/testthat/helper-vcr.R with dry-run defaults, delete all 673 untracked cassettes using these helpers, create a re-recording script using mirai with 8 workers and exponential backoff, prioritize Chemical domain and chemi_search/chemi_resolver_lookup functions for first re-recording batch.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- All helpers live in `tests/testthat/helper-vcr.R` — NOT exported as package functions
- `delete_all_cassettes()` and `delete_cassettes(pattern)` default to dry-run mode — must pass `dry_run = FALSE` to actually delete files
- `list_cassettes()` returns a simple character vector of cassette filenames (no metadata)
- `check_cassette_safety()` accepts optional cassette name or pattern — no args scans all cassettes
- All 673 untracked .yml files in `tests/testthat/fixtures/` are from the bad generator run — delete all of them
- Use the newly built helper functions to perform the deletion (dogfooding the tools)
- Separate commits: one commit adds helper functions, another commit deletes bad cassettes using them
- Priority domains for first re-recording batch: Chemical (`ct_chemical_*`), `chemi_search`, `chemi_resolver_lookup`
- Parallel execution using `mirai` with 8 workers
- Exponential backoff on HTTP 429 (rate limit) responses
- On failure (API error, timeout): skip the cassette, log it to a failures file, continue with remaining cassettes
- Re-run failures separately after initial batch completes
- Scan current working tree cassettes only — no git history scanning
- Check for: actual API key string values AND auth-related headers (Authorization, Bearer, x-api-key with real values)
- Report-only mode: print which cassettes have issues and where, no auto-fix
- Manual tool — no pre-commit hook integration

### Claude's Discretion
- Whether to keep or delete currently tracked (committed) cassettes based on validity assessment
- Exact backoff timing/curve for rate limit handling
- Re-recording script file location and naming
- Failure log format

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| VCR-01 | All 673 untracked cassettes recorded with wrong parameters are deleted | Helper functions section, File deletion workflow |
| VCR-02 | `delete_all_cassettes()` function implemented in helper-vcr.R for bulk cassette deletion | vcr package configuration, Helper functions section |
| VCR-03 | `delete_cassettes(pattern)` function implemented for pattern-based cassette deletion | vcr package configuration, Helper functions section |
| VCR-04 | `list_cassettes()` function implemented to enumerate existing cassettes | vcr package configuration, Helper functions section |
| VCR-05 | `check_cassette_safety()` function implemented to scan cassettes for leaked API keys | vcr filter_sensitive_data, API key security section |
| VCR-06 | Security audit confirms all committed cassettes are API-key filtered (show `<<<API_KEY>>>` not actual keys) | vcr filter_sensitive_data, API key security section |
| VCR-07 | Cassette re-recording script supports batched execution (20-50 at a time) with rate-limit delays | mirai parallel execution, httr2 req_retry with exponential backoff |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| vcr | 2.1.0 | HTTP interaction recording/replaying | Industry standard for R API testing, already in use |
| mirai | 2.6.0+ | Parallel execution with minimal overhead | R-lib official async framework, already in dev dependencies |
| httr2 | latest | HTTP requests with retry logic | Modern R HTTP client with built-in exponential backoff, already core dependency |
| fs | latest | Cross-platform filesystem operations | Safe file operations, already in project |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| yaml | latest | Parse cassette YAML files | For API key security scanning |
| cli | latest | User feedback and progress indicators | Already core dependency for messaging |
| purrr | latest | Functional iteration over cassettes | Already core dependency |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| mirai | parallel/future | mirai offers C-level dispatcher with microsecond overhead vs millisecond with base R parallel |
| vcr | httptest2 | Would require rewriting 706+ cassettes; vcr is working and has better filtering |
| custom deletion | unlink | fs provides better error handling and cross-platform compatibility |

**Installation:**
All required packages already in project dependencies. mirai is installed but not in DESCRIPTION — add to Suggests if needed for re-recording script.

## Architecture Patterns

### Recommended Project Structure
```
tests/testthat/
├── helper-vcr.R              # NEW: VCR helper functions
├── fixtures/                 # Cassette storage
│   ├── *.yml                # 706 total cassettes (33 tracked + 673 untracked)
└── test-*.R                 # Test files using cassettes

dev/
├── rerecord_cassettes.R     # NEW: Parallel re-recording script
└── [existing scripts]
```

### Pattern 1: Safe Cassette Deletion with Dry-Run Default

**What:** All destructive operations default to dry-run mode, requiring explicit confirmation
**When to use:** Any cassette deletion operation
**Example:**
```r
# Source: User requirements, standard R practice
delete_all_cassettes <- function(dry_run = TRUE) {
  cassette_dir <- here::here("tests/testthat/fixtures")
  cassettes <- fs::dir_ls(cassette_dir, glob = "*.yml")

  if (dry_run) {
    cli::cli_alert_info("DRY RUN: Would delete {length(cassettes)} cassettes")
    cli::cli_alert_warning("Set dry_run = FALSE to actually delete")
    return(invisible(cassettes))
  }

  cli::cli_alert_danger("Deleting {length(cassettes)} cassettes...")
  fs::file_delete(cassettes)
  cli::cli_alert_success("Deleted {length(cassettes)} cassettes")
  invisible(cassettes)
}
```

### Pattern 2: Parallel Re-recording with mirai

**What:** Use mirai's daemon pool for parallel cassette re-recording
**When to use:** Re-recording large batches of cassettes (50+ functions)
**Example:**
```r
# Source: mirai 2.6.0 documentation
# https://mirai.r-lib.org/

library(mirai)

# Initialize daemon pool (8 workers per user requirements)
daemons(n = 8)

# Submit tasks
results <- lapply(test_files, function(file) {
  mirai({
    devtools::test_file(file)
  })
})

# Collect results
collected <- lapply(results, call_mirai)

# Cleanup
daemons(0)
```

### Pattern 3: Exponential Backoff for Rate Limiting

**What:** httr2's built-in retry with exponential backoff and Retry-After header support
**When to use:** Already implemented in generic_request(), use for re-recording script
**Example:**
```r
# Source: httr2 documentation, already in z_generic_request.R
# https://httr2.r-lib.org/reference/req_retry.html

is_transient_error <- function(resp) {
  status <- httr2::resp_status(resp)
  # 429 = rate limit, 5xx = server errors
  status == 429 || (status >= 500 && status < 600)
}

req <- req %>%
  httr2::req_retry(
    max_tries = 3,
    is_transient = is_transient_error
  )
```

### Pattern 4: API Key Security Scanning

**What:** Parse YAML cassettes to detect unfiltered API keys or auth headers
**When to use:** Before committing new cassettes, audit existing cassettes
**Example:**
```r
# Source: vcr 2.1.0 configuration and YAML parsing pattern
check_cassette_safety <- function(pattern = NULL) {
  cassette_dir <- here::here("tests/testthat/fixtures")

  if (is.null(pattern)) {
    files <- fs::dir_ls(cassette_dir, glob = "*.yml")
  } else {
    files <- fs::dir_ls(cassette_dir, regexp = pattern)
  }

  issues <- list()

  for (file in files) {
    content <- readLines(file, warn = FALSE)

    # Check for auth headers with actual values
    if (any(grepl("x-api-key:", content, ignore.case = TRUE))) {
      header_lines <- grep("x-api-key:", content, ignore.case = TRUE, value = TRUE)
      # If not filtered, won't show <<<API_KEY>>>
      if (!any(grepl("<<<API_KEY>>>", header_lines))) {
        issues[[file]] <- "Unfiltered x-api-key header"
      }
    }

    # Check for Authorization/Bearer headers
    if (any(grepl("Authorization:", content, ignore.case = TRUE))) {
      auth_lines <- grep("Authorization:", content, ignore.case = TRUE, value = TRUE)
      if (any(grepl("Bearer [A-Za-z0-9]+", auth_lines))) {
        issues[[file]] <- "Unfiltered Authorization Bearer token"
      }
    }
  }

  if (length(issues) > 0) {
    cli::cli_alert_danger("Found {length(issues)} cassettes with potential API key leaks")
    purrr::iwalk(issues, ~cli::cli_alert_warning("{.file {.y}}: {.x}"))
  } else {
    cli::cli_alert_success("All {length(files)} cassettes are API-key safe")
  }

  invisible(issues)
}
```

### Anti-Patterns to Avoid
- **Blind deletion without dry-run:** Always default to dry-run mode for destructive operations
- **Synchronous re-recording of 100+ tests:** Use parallel execution to respect time constraints
- **Ignoring Retry-After headers:** httr2 handles this automatically, don't override
- **Hardcoding backoff timing:** Use httr2's default exponential backoff with jitter
- **Auto-fixing leaked API keys:** Report-only mode prevents accidental data loss

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exponential backoff | Custom retry loops with `Sys.sleep()` | `httr2::req_retry()` | httr2 implements truncated exponential backoff with full jitter, respects Retry-After headers, handles 429/503 by default |
| Parallel execution | Base `parallel::mclapply()` | `mirai` with daemons | mirai has C-level dispatcher (microsecond overhead), better error handling, works across platforms |
| Cassette deletion | `file.remove()` with glob patterns | `fs::file_delete()` with `fs::dir_ls()` | fs provides better error messages, cross-platform compatibility, and safer defaults |
| YAML parsing for security scan | Custom regex on raw text | `yaml::read_yaml()` + targeted checks | Structured parsing prevents false positives from YAML string escaping |

**Key insight:** The R ecosystem already has production-grade solutions for all Phase 24 requirements. httr2's retry logic is already integrated into the project's generic_request() template, so re-recording will automatically benefit from exponential backoff without any additional code.

## Common Pitfalls

### Pitfall 1: Deleting Tracked Cassettes Without Verification

**What goes wrong:** Accidentally deleting committed cassettes that are valid, requiring expensive production API re-recording
**Why it happens:** Confusion between untracked (673 bad cassettes from Phase 23) and tracked (33 existing valid cassettes)
**How to avoid:** Always check git status before deletion; helper functions should work on untracked files only by default
**Warning signs:** `git status` shows deleted tracked files after running deletion helper

### Pitfall 2: Rate Limit Exhaustion During Re-recording

**What goes wrong:** Parallel workers all hit rate limits simultaneously, causing cascade of 429 errors and wasted time
**Why it happens:** No coordination between parallel workers, all workers retry at same time
**How to avoid:**
- Use mirai with 8 workers (not more) per user requirements
- httr2's exponential backoff with jitter prevents thundering herd
- Add base delay between cassette recordings (e.g., 0.5-1 second)
**Warning signs:** Logs show multiple 429 errors at same timestamp, Retry-After headers showing increasing wait times

### Pitfall 3: API Key Leaks in New Cassettes

**What goes wrong:** Re-recorded cassettes contain actual API keys instead of <<<API_KEY>>> placeholder
**Why it happens:** vcr filter_sensitive_data not properly configured, or API key env var empty during recording
**How to avoid:**
- Verify `Sys.getenv("ctx_api_key")` is set before re-recording
- Check that helper-vcr.R has `filter_sensitive_data` configured (already present)
- Run `check_cassette_safety()` after re-recording before committing
**Warning signs:** grep finds actual key values in cassettes, cassettes work locally but fail in CI

### Pitfall 4: Incomplete Test Recording (Empty Cassettes)

**What goes wrong:** Test runs but cassette is empty or missing HTTP interactions
**Why it happens:** Test skipped due to error, vcr not properly wrapping HTTP calls, network issues
**How to avoid:**
- Check vcr `warn_on_empty_cassette` is enabled (default in vcr 2.1.0)
- Log which tests succeed/fail during re-recording
- Re-run failures separately with verbose mode
**Warning signs:** Cassette file exists but is tiny (<100 bytes), tests pass locally but fail in CI

### Pitfall 5: Mixing Cassette Naming Conventions

**What goes wrong:** Cannot find cassettes because test generator used different naming than manual tests
**Why it happens:** Phase 23 test generator uses specific naming pattern (function_name_variant), manual tests may differ
**How to avoid:** Stick to test generator naming convention: `{function_name}_{variant}` where variant is single/batch/error/example
**Warning signs:** Tests fail with "cassette not found" errors after re-recording

## Code Examples

Verified patterns from official sources and project code:

### VCR Configuration (Already Present)
```r
# Source: tests/testthat/helper-vcr.R (existing)
library(vcr)

vcr_dir <- "../testthat/fixtures"
if (!dir.exists(vcr_dir)) dir.create(vcr_dir, recursive = TRUE)

vcr::vcr_configure(
  dir = vcr_dir,
  filter_sensitive_data = list(
    "<<<API_KEY>>>" = Sys.getenv("ctx_api_key")
  )
)
```

### List Cassettes Helper
```r
# Simple character vector of cassette filenames
list_cassettes <- function() {
  cassette_dir <- here::here("tests/testthat/fixtures")
  files <- fs::dir_ls(cassette_dir, glob = "*.yml")
  # Return just filenames, not full paths
  fs::path_file(files)
}
```

### Pattern-Based Deletion
```r
delete_cassettes <- function(pattern, dry_run = TRUE) {
  cassette_dir <- here::here("tests/testthat/fixtures")

  # Support both glob patterns (*.yml) and regex patterns
  if (grepl("\\*", pattern)) {
    files <- fs::dir_ls(cassette_dir, glob = pattern)
  } else {
    files <- fs::dir_ls(cassette_dir, regexp = pattern)
  }

  if (length(files) == 0) {
    cli::cli_alert_warning("No cassettes match pattern: {pattern}")
    return(invisible(character(0)))
  }

  if (dry_run) {
    cli::cli_alert_info("DRY RUN: Would delete {length(files)} cassettes matching '{pattern}'")
    cli::cli_bullets(fs::path_file(files))
    cli::cli_alert_warning("Set dry_run = FALSE to actually delete")
    return(invisible(files))
  }

  cli::cli_alert_danger("Deleting {length(files)} cassettes matching '{pattern}'...")
  fs::file_delete(files)
  cli::cli_alert_success("Deleted {length(files)} cassettes")
  invisible(files)
}
```

### Parallel Re-recording Script Structure
```r
# Source: mirai 2.6.0 patterns
# https://mirai.r-lib.org/

library(mirai)
library(cli)
library(fs)

# Configuration
N_WORKERS <- 8
CASSETTE_DIR <- here::here("tests/testthat/fixtures")
LOG_FILE <- here::here("dev/rerecord_failures.log")

# Priority functions (from user requirements)
PRIORITY_PATTERNS <- c(
  "test-ct_chemical*.R",
  "test-chemi_search.R",
  "test-chemi_resolver_lookup.R"
)

# Initialize daemon pool
daemons(n = N_WORKERS)

# Get test files
test_dir <- here::here("tests/testthat")
priority_files <- unlist(lapply(PRIORITY_PATTERNS, function(p) {
  fs::dir_ls(test_dir, glob = p)
}))

cli::cli_alert_info("Re-recording {length(priority_files)} priority test files with {N_WORKERS} workers")

# Submit tasks
results <- lapply(priority_files, function(file) {
  mirai({
    # Delete cassettes for this test
    test_name <- tools::file_path_sans_ext(basename(file))
    pattern <- paste0(test_name, "*.yml")
    fs::file_delete(fs::dir_ls(CASSETTE_DIR, glob = pattern))

    # Re-run test (will record new cassettes)
    testthat::test_file(file, reporter = "minimal")
  })
})

# Collect results with progress
failures <- character(0)
cli::cli_progress_bar("Re-recording cassettes", total = length(results))

for (i in seq_along(results)) {
  result <- call_mirai(results[[i]])

  if (inherits(result, "error")) {
    failures <- c(failures, priority_files[i])
  }

  cli::cli_progress_update()
}

cli::cli_progress_done()

# Cleanup
daemons(0)

# Report results
if (length(failures) > 0) {
  cli::cli_alert_danger("Failed to re-record {length(failures)} test files")
  writeLines(failures, LOG_FILE)
  cli::cli_alert_info("Failures logged to {.file {LOG_FILE}}")
} else {
  cli::cli_alert_success("Successfully re-recorded all {length(priority_files)} test files")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual cassette deletion via shell | Helper functions with dry-run | Phase 24 | Safer, more maintainable |
| Sequential test re-recording | Parallel with mirai | Phase 24 | ~8x faster for 50+ tests |
| Base parallel package | mirai with C-level dispatcher | mirai 2.6.0 (Feb 2026) | Microsecond vs millisecond overhead |
| Manual backoff in retry loops | httr2 req_retry | httr2 1.0+ | Automatic jitter, Retry-After support |

**Deprecated/outdated:**
- `httr::RETRY()`: Use `httr2::req_retry()` instead (better backoff, cleaner API)
- `webmockr` for cassette management: vcr is more actively maintained and has better filtering
- Manual `Sys.sleep()` for rate limiting: httr2 handles this automatically

## Open Questions

1. **Should we delete existing tracked cassettes?**
   - What we know: 33 cassettes are tracked, 673 are untracked bad ones
   - What's unclear: Whether tracked cassettes are from old generator or manual creation
   - Recommendation: Keep tracked cassettes initially; if tests fail after Phase 23 changes, delete and re-record selectively

2. **What backoff curve for re-recording script?**
   - What we know: httr2 uses truncated exponential backoff with full jitter by default
   - What's unclear: Whether to add additional delay between cassettes to prevent coordinated retry storms
   - Recommendation: Use httr2 defaults (already proven in generic_request); add 0.5s base delay between test files if rate limits hit

3. **Re-recording script location?**
   - What we know: dev/ directory contains generation scripts
   - What's unclear: Whether this is one-time script or should be maintained long-term
   - Recommendation: Place in dev/rerecord_cassettes.R (matches dev/generate_tests.R pattern); document usage in CLAUDE.md

## Validation Architecture

> Phase does not require new automated tests — validation is manual verification of cassette cleanup and re-recording success.

**Validation checklist:**
- [ ] All 673 untracked cassettes deleted from filesystem
- [ ] Helper functions exist and work with dry-run mode
- [ ] `check_cassette_safety()` confirms no API key leaks in committed cassettes
- [ ] Re-recording script completes without rate limit exhaustion
- [ ] Priority domain tests pass with new cassettes (Chemical, chemi_search, chemi_resolver_lookup)
- [ ] R CMD check still passes with new cassettes

## Sources

### Primary (HIGH confidence)
- [vcr R package CRAN documentation](https://cran.r-project.org/web/packages/vcr/vcr.pdf) - vcr 2.1.0 configuration and filter_sensitive_data
- [vcr source: filter_sensitive_data.R](https://rdrr.io/cran/vcr/src/R/filter_sensitive_data.R) - API key filtering implementation
- [mirai official documentation](https://mirai.r-lib.org/) - Parallel execution patterns with daemons
- [mirai 2.6.0 release announcement](https://tidyverse.org/blog/2026/02/mirai-2-6-0/) - C-level dispatcher performance
- [httr2 req_retry documentation](https://httr2.r-lib.org/reference/req_retry.html) - Exponential backoff with jitter
- Project code: tests/testthat/helper-vcr.R (existing vcr configuration)
- Project code: R/z_generic_request.R (existing is_transient_error implementation)

### Secondary (MEDIUM confidence)
- [AWS retry with backoff pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html) - Industry best practices for exponential backoff
- [Postman HTTP 429 guide](https://blog.postman.com/http-error-429/) - Rate limiting best practices
- [How to handle API rate limits (2026 guide)](https://apistatuscheck.com/blog/how-to-handle-api-rate-limits) - Exponential backoff with jitter recommendations

### Tertiary (LOW confidence)
None — all critical information verified from official sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already in project, versions verified from CRAN/official docs
- Architecture: HIGH - Patterns verified from official docs and existing project code
- Pitfalls: HIGH - Based on project history (Phase 23 test generator issues) and R testing best practices

**Research date:** 2026-02-27
**Valid until:** 2026-05-27 (90 days - stable R package ecosystem, mirai 2.6.0 just released)
