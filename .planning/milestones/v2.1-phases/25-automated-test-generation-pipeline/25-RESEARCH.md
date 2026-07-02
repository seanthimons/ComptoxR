# Phase 25: Automated Test Generation Pipeline - Research

**Researched:** 2026-02-28
**Domain:** CI/CD automation, R package testing, static code analysis
**Confidence:** HIGH

## Summary

Phase 25 integrates test gap detection and generation into the existing schema-check.yml GitHub Actions workflow, creating a complete pipeline: schemas → stubs → docs → **detect gaps → generate tests** → coverage → PR. The implementation leverages R's native `parse()` AST parsing for function detection, existing test generator from Phase 23, and GitHub Actions output variables for PR reporting.

Key findings: (1) R's `parse()` and `formals()` provide robust AST-based function analysis without external dependencies, (2) GitHub Actions GITHUB_OUTPUT environment file is the current standard for inter-step communication (deprecates set-output), (3) JSON manifests are well-established in R ecosystem for tracking metadata, (4) The existing dev/ scripts and workflow patterns provide clear templates to follow.

**Primary recommendation:** Extend `dev/generate_tests.R` with gap detection logic using AST parsing, create `dev/detect_test_gaps.R` as a separate reporting script, add two workflow steps to schema-check.yml after stub generation, and implement a simple JSON manifest at `dev/test_manifest.json` for protected file tracking.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- A "gap" is an exported function that calls `generic_request()` or `generic_chemi_request()` and either has no test file or has a test file without real `test_that()` blocks
- Detection scans function bodies for calls to any `generic_*` function in `z_generic_request.R`
- Non-API utility functions are excluded from automated gap detection (they need different test approaches)
- Test files with no actual assertions (empty skeletons) still count as gaps
- Output: structured report file (JSON or CSV) to `dev/reports/` with function name, file path, and gap reason; also prints summary to stdout
- Test generation steps added directly to existing `schema-check.yml` (not a separate workflow)
- Pipeline order: schemas → stubs → docs → **detect gaps → generate tests** → coverage → PR
- Triggers: auto on stub file changes + manual `workflow_dispatch`
- Generated tests committed to the same automated branch as schemas/stubs
- PR body extended with a "Test Gaps" report section showing tests generated and remaining gaps
- Auto-maintained manifest at `dev/test_manifest.json` tracks each test file as "generated" or "protected"
- Generator automatically adds entries when creating new test files
- Developers manually mark files as "protected" when they customize them
- Protected files are never overwritten by the generator
- Protected files whose underlying function signature has changed are flagged as warnings in the gap report (staleness detection)
- Manifest tracks status only (no signature hashes or dates) — simple and low maintenance
- Separate standalone scripts: `dev/detect_test_gaps.R` and `dev/generate_tests.R`
- Both work independently when run locally (outside CI)
- CI chains them as separate steps (no wrapper orchestrator script)
- Test generation outputs GITHUB_OUTPUT variables matching the stub generator pattern (tests_generated, tests_skipped, gaps_remaining) for PR body reporting

### Claude's Discretion
- Internal report format details (JSON vs CSV)
- Exact staleness detection heuristic for protected files
- How to handle edge cases (functions with multiple generic_request calls, internal helpers that happen to use generic_request)
- PR body formatting and section ordering

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTO-01 | `dev/detect_test_gaps.R` script identifies functions in R/ without corresponding test files | R AST parsing via `parse()` + function call detection patterns; existing codebase search utilities in `dev/endpoint_eval/03_codebase_search.R` |
| AUTO-02 | `dev/generate_tests.R` script generates tests for all detected gaps using the fixed test generator | Extend existing `dev/generate_tests.R` (Phase 23); metadata-aware test generation already implemented |
| AUTO-03 | GitHub Action workflow detects new/changed stubs and generates corresponding test files | GitHub Actions step chaining; GITHUB_OUTPUT variables for step communication |
| AUTO-04 | CI reports test gap count and coverage metrics in workflow summary | GitHub Actions job summaries ($GITHUB_STEP_SUMMARY); PR body markdown templating from schema-check.yml |
| AUTO-05 | Coverage thresholds tuned for generated code (exclude auto-generated stubs from strict thresholds or use tiered rates) | R covr package; existing `dev/calculate_coverage.R` script for coverage reporting |
| AUTO-06 | Test generation is integrated into stub generation pipeline | Workflow step ordering in schema-check.yml; existing pattern of chained steps (schemas → stubs → docs → coverage) |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| R base::parse() | R 4.5.1+ | AST parsing for function detection | Native R capability, zero dependencies, robust |
| R base::formals() | R 4.5.1+ | Extract function parameters from parsed code | Native R, part of standard static analysis workflow |
| R cli | Current | User-facing output formatting | Already used throughout project, consistent UX |
| R fs | Current | File system operations | Already used in project (rerecord_cassettes.R), safer than base R |
| R jsonlite | Current | JSON manifest read/write | Already a dependency, standard R JSON library |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| R testthat | 3.3.2+ | Test file detection (test_that blocks) | Parse existing test files to detect empty skeletons |
| R covr | Current | Test coverage reporting | Coverage metrics for AUTO-04 reporting |
| GitHub Actions GITHUB_OUTPUT | Current | Inter-step communication | Passing test gap counts to PR body generation |
| GitHub Actions $GITHUB_STEP_SUMMARY | Current | Workflow summary formatting | Detailed gap report in job summary UI |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native parse() | lintr XML parsing | lintr adds complexity for XPath queries; native parse() is sufficient for simple function call detection |
| JSON manifest | SQLite database | SQLite overkill for simple key-value tracking; JSON easier to edit manually |
| Chained workflow steps | Separate workflow | Separate workflow increases complexity; chaining keeps all schema updates in one PR |

**Installation:**
```r
# All dependencies already in project
# No new packages required for core functionality
```

## Architecture Patterns

### Recommended Project Structure
```
dev/
├── detect_test_gaps.R       # Gap detection script (NEW)
├── generate_tests.R          # Test generator (EXTEND)
├── test_manifest.json        # Protected file tracking (NEW)
└── reports/                  # Gap reports output (NEW)
    └── test_gaps_YYYYMMDD.json

tests/testthat/
├── test-ct_*.R              # Generated test files
├── test-chemi_*.R
└── helper-vcr.R

.github/workflows/
└── schema-check.yml          # Add gap detection + test generation steps
```

### Pattern 1: AST-Based Function Call Detection
**What:** Use R's native `parse()` to analyze function bodies and detect calls to `generic_request()` or `generic_chemi_request()`
**When to use:** Gap detection for any R function that calls specific internal functions
**Example:**
```r
# Source: Existing dev/generate_tests.R extract_function_formals()
detect_generic_request_call <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)

  # Search for generic_request, generic_chemi_request, or generic_cc_request calls
  patterns <- c(
    "generic_request\\(",
    "generic_chemi_request\\(",
    "generic_cc_request\\("
  )

  for (pattern in patterns) {
    if (any(grepl(pattern, lines))) {
      return(TRUE)
    }
  }

  FALSE
}

# Enhanced version: detect ALL generic_* functions from z_generic_request.R
detect_any_generic_call <- function(file_path, generic_functions) {
  expr <- parse(file = file_path)

  # Walk AST to find function calls
  all_calls <- unlist(lapply(expr, all.names))
  any(generic_functions %in% all_calls)
}
```

### Pattern 2: GITHUB_OUTPUT Variables for Step Communication
**What:** Use `$GITHUB_OUTPUT` environment file to pass data between workflow steps
**When to use:** Communicating test counts, gap metrics, or any data from R script to subsequent workflow steps
**Example:**
```r
# Source: https://docs.github.com/actions/writing-workflows/choosing-what-your-workflow-does/passing-information-between-jobs
# From schema-check.yml diff step (lines 157-160)

gh_output <- Sys.getenv("GITHUB_OUTPUT")
cat(sprintf("tests_generated=%d\n", generated_count), file = gh_output, append = TRUE)
cat(sprintf("tests_skipped=%d\n", skipped_count), file = gh_output, append = TRUE)
cat(sprintf("gaps_remaining=%d\n", gaps_remaining), file = gh_output, append = TRUE)
```

In workflow YAML:
```yaml
- name: Generate tests
  id: tests
  run: Rscript dev/generate_tests.R
  shell: bash

- name: Use outputs in PR body
  run: |
    echo "Tests generated: ${{ steps.tests.outputs.tests_generated }}"
    echo "Gaps remaining: ${{ steps.tests.outputs.gaps_remaining }}"
```

### Pattern 3: JSON Manifest for Metadata Tracking
**What:** Simple JSON file tracking test file status (generated vs protected)
**When to use:** Maintaining state between CI runs without database overhead
**Example:**
```json
{
  "version": "1.0",
  "updated": "2026-02-28T12:00:00Z",
  "files": {
    "test-ct_hazard.R": {
      "status": "protected",
      "protected_date": "2026-02-15T10:30:00Z",
      "reason": "custom assertions added"
    },
    "test-ct_cancer.R": {
      "status": "generated",
      "generated_date": "2026-02-28T12:00:00Z"
    }
  }
}
```

R code to interact:
```r
# Source: Posit Connect manifest.json pattern (https://docs.posit.co/connect/user/manifest/)
read_test_manifest <- function() {
  manifest_path <- here::here("dev/test_manifest.json")
  if (!file.exists(manifest_path)) {
    return(list(version = "1.0", files = list()))
  }
  jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
}

mark_as_protected <- function(test_file, reason = "") {
  manifest <- read_test_manifest()
  manifest$files[[test_file]] <- list(
    status = "protected",
    protected_date = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
    reason = reason
  )
  manifest$updated <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
  jsonlite::write_json(manifest, here::here("dev/test_manifest.json"),
                       pretty = TRUE, auto_unbox = TRUE)
}
```

### Pattern 4: Workflow Step Chaining
**What:** Add test generation steps after stub generation in schema-check.yml
**When to use:** Extending existing workflows with new automation steps
**Example:**
```yaml
# Source: Existing schema-check.yml pattern (lines 180-198)
- name: Generate function stubs
  id: stubs
  if: steps.schema_changes.outputs.changed == 'true'
  run: |
    source("dev/generate_stubs.R")
  shell: Rscript {0}

- name: Update documentation
  if: steps.schema_changes.outputs.changed == 'true'
  run: |
    devtools::document()
  shell: Rscript {0}

# NEW STEPS (insert after documentation)
- name: Detect test gaps
  id: gaps
  if: steps.schema_changes.outputs.changed == 'true'
  run: |
    source("dev/detect_test_gaps.R")
  shell: Rscript {0}

- name: Generate tests
  id: tests
  if: steps.gaps.outputs.gaps_found == 'true'
  run: |
    source("dev/generate_tests.R")
  shell: Rscript {0}

- name: Calculate coverage
  id: coverage
  if: steps.schema_changes.outputs.changed == 'true'
  run: |
    source("dev/calculate_coverage.R")
  shell: Rscript {0}
```

### Pattern 5: Staleness Detection Without Hash Tracking
**What:** Detect signature changes by comparing function formals against last known state
**When to use:** Warn when protected test files might be outdated
**Example:**
```r
detect_stale_protected_files <- function() {
  manifest <- read_test_manifest()
  protected_files <- names(manifest$files)[
    sapply(manifest$files, function(f) f$status == "protected")
  ]

  stale <- list()
  for (test_file in protected_files) {
    # Extract function name from test file
    fn_name <- gsub("^test-|\\.R$", "", test_file)
    fn_file <- file.path("R", paste0(fn_name, ".R"))

    if (!file.exists(fn_file)) {
      stale[[test_file]] <- "function file deleted"
      next
    }

    # Simple heuristic: check if function still calls generic_request
    if (!detect_generic_request_call(fn_file)) {
      stale[[test_file]] <- "no longer calls generic_request"
    }
  }

  stale
}
```

### Anti-Patterns to Avoid
- **Re-parsing on every check:** Parse function files once per gap detection run, cache results in memory
- **Overwriting protected files silently:** Always check manifest before writing; abort with clear error if protected
- **Deep AST walking for simple patterns:** Use regex on readLines() for simple function call detection; reserve parse() for complex analysis
- **Signature hashing:** Adds complexity with minimal benefit; simple timestamp + manual review is sufficient

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Test file parsing | Custom regex for test_that() detection | testthat internal structure awareness + simple `grepl("test_that\\(", lines)` | test_that blocks have consistent syntax; simple regex sufficient; don't need full testthat parser |
| Function call detection | Custom R parser | R base::parse() + all.names() | R's native parser handles all edge cases (multi-line, comments, strings); battle-tested |
| Workflow step outputs | Custom artifact files | GITHUB_OUTPUT environment file | GitHub Actions standard; automatic cleanup; type-safe variable passing |
| JSON validation | Custom schema validator | Simple structure validation in R | Manifest is simple key-value; jsonlite handles parsing; manual validation sufficient |
| Protected file UI | Custom CLI prompts | Manual JSON editing + git diff review | Developers edit JSON rarely; git history provides audit trail; CLI adds complexity |

**Key insight:** R's built-in AST tools (parse, formals, all.names) are production-ready for static analysis. The project already has excellent patterns for CI integration (schema-check.yml). Don't reinvent; extend existing patterns.

## Common Pitfalls

### Pitfall 1: Missing GITHUB_OUTPUT in Local Runs
**What goes wrong:** Scripts fail when run locally because `Sys.getenv("GITHUB_OUTPUT")` returns empty string
**Why it happens:** GITHUB_OUTPUT is a CI-only environment variable
**How to avoid:** Conditional output writing with fallback to stdout/file
**Warning signs:** Script works in CI but fails when run locally with `Rscript dev/detect_test_gaps.R`
```r
# Solution:
gh_output <- Sys.getenv("GITHUB_OUTPUT")
if (nzchar(gh_output)) {
  # CI mode: write to GITHUB_OUTPUT
  cat(sprintf("gaps_found=%s\n", gaps > 0), file = gh_output, append = TRUE)
} else {
  # Local mode: write to console
  cli::cli_alert_info("Gaps found: {gaps > 0}")
}
```

### Pitfall 2: Incorrect Function Name Extraction from File Paths
**What goes wrong:** Functions with underscores or hyphens in filenames parsed incorrectly
**Why it happens:** Inconsistent naming conventions (ct_hazard.R vs ct_hazard_toxval.R vs test-ct_hazard.R)
**How to avoid:** Use tools::file_path_sans_ext() and preserve exact filename → function name mapping
**Warning signs:** Gap detector reports "function not found" for files that clearly exist
```r
# Correct:
function_name <- tools::file_path_sans_ext(basename(r_file))  # "ct_hazard_toxval"
test_file <- file.path("tests/testthat", paste0("test-", function_name, ".R"))

# Incorrect:
function_name <- gsub("_.*", "", basename(r_file))  # "ct" (truncated!)
```

### Pitfall 3: Empty Test Files Count as Covered
**What goes wrong:** Test files exist but contain no actual test_that() blocks, so gaps aren't detected
**Why it happens:** Generator creates skeleton files; developer saves without filling in tests
**How to avoid:** Parse test files and require at least one `test_that()` call
**Warning signs:** High "test coverage" but low actual assertion count
```r
has_real_tests <- function(test_file) {
  if (!file.exists(test_file)) return(FALSE)

  lines <- readLines(test_file, warn = FALSE)
  # Must contain at least one test_that() call
  any(grepl("test_that\\s*\\(", lines))
}
```

### Pitfall 4: Protected File Overwrites
**What goes wrong:** Test generator overwrites a protected file because manifest wasn't checked
**Why it happens:** Forgot to check manifest before writing; force flag bypasses protection
**How to avoid:** ALWAYS read manifest first; fail loudly if attempting to overwrite protected file
**Warning signs:** Developer complaints about lost customizations; git diff shows test rewrites
```r
# In generate_test_file():
manifest <- read_test_manifest()
if (!is.null(manifest$files[[test_file]]) &&
    manifest$files[[test_file]]$status == "protected") {
  cli::cli_abort(c(
    "x" = "Cannot overwrite protected test: {test_file}",
    "i" = "Remove from manifest or use --force flag with caution"
  ))
}
```

### Pitfall 5: Multiline Function Calls Break Regex Detection
**What goes wrong:** `generic_request(` on one line, parameters on next lines → regex misses it
**Why it happens:** Regex searches line-by-line without context
**How to avoid:** Use full file content or multi-line-aware patterns
**Warning signs:** Functions clearly calling generic_request not detected as gaps
```r
# Solution: read full file as single string or use parse()
detect_generic_request <- function(file_path) {
  # Read entire file
  content <- paste(readLines(file_path, warn = FALSE), collapse = "\n")
  # Multi-line pattern
  grepl("generic_(request|chemi_request|cc_request)\\s*\\(", content)
}

# Or use AST (even better):
expr <- parse(file = file_path)
all_calls <- unlist(lapply(expr, all.names))
any(c("generic_request", "generic_chemi_request", "generic_cc_request") %in% all_calls)
```

## Code Examples

Verified patterns from existing codebase and official sources:

### Gap Detection Script Structure
```r
# Source: Adapted from dev/generate_tests.R pattern
#!/usr/bin/env Rscript
# dev/detect_test_gaps.R

library(cli)
library(fs)
library(here)
library(jsonlite)

# Find all R function files calling generic_* functions
detect_gaps <- function() {
  cli::cli_h1("Detecting Test Gaps")

  # Find all API wrapper files
  r_files <- fs::dir_ls(
    here::here("R"),
    regexp = "^(ct_|chemi_|cc_)[^.]+\\.R$"
  )

  gaps <- list()

  for (r_file in r_files) {
    fn_name <- tools::file_path_sans_ext(fs::path_file(r_file))
    test_file <- here::here("tests/testthat", paste0("test-", fn_name, ".R"))

    # Check if it calls generic_request
    if (!calls_generic_request(r_file)) {
      next  # Skip non-API functions
    }

    # Check gap conditions
    gap_reason <- NULL
    if (!fs::file_exists(test_file)) {
      gap_reason <- "no_test_file"
    } else if (!has_real_tests(test_file)) {
      gap_reason <- "empty_test_file"
    }

    if (!is.null(gap_reason)) {
      gaps[[fn_name]] <- list(
        function_name = fn_name,
        file_path = as.character(r_file),
        test_file = as.character(test_file),
        reason = gap_reason
      )
    }
  }

  # Write report
  report_dir <- here::here("dev/reports")
  if (!fs::dir_exists(report_dir)) {
    fs::dir_create(report_dir, recurse = TRUE)
  }

  report_file <- fs::path(
    report_dir,
    paste0("test_gaps_", format(Sys.Date(), "%Y%m%d"), ".json")
  )

  jsonlite::write_json(gaps, report_file, pretty = TRUE, auto_unbox = TRUE)

  # Output to GITHUB_OUTPUT if in CI
  gh_output <- Sys.getenv("GITHUB_OUTPUT")
  if (nzchar(gh_output)) {
    cat(sprintf("gaps_found=%s\n", length(gaps) > 0),
        file = gh_output, append = TRUE)
    cat(sprintf("gaps_count=%d\n", length(gaps)),
        file = gh_output, append = TRUE)
  }

  cli::cli_alert_success("Found {length(gaps)} gap{?s}")
  cli::cli_alert_info("Report: {report_file}")

  invisible(gaps)
}

# Helper: detect generic_request calls
calls_generic_request <- function(file_path) {
  expr <- parse(file = file_path)
  all_calls <- unlist(lapply(expr, all.names))
  any(c("generic_request", "generic_chemi_request", "generic_cc_request") %in% all_calls)
}

# Helper: check if test file has real tests
has_real_tests <- function(test_file) {
  if (!file.exists(test_file)) return(FALSE)
  lines <- readLines(test_file, warn = FALSE)
  any(grepl("test_that\\s*\\(", lines))
}

# Run if sourced
if (!interactive()) {
  detect_gaps()
}
```

### Extended Test Generator with Manifest Support
```r
# Source: Extend existing dev/generate_tests.R
# Add to generate_test_file() function:

generate_test_file <- function(function_name, function_file, output_dir = "tests/testthat") {
  # CHECK MANIFEST FIRST
  manifest <- read_test_manifest()
  test_file <- file.path(output_dir, paste0("test-", function_name, ".R"))

  if (!is.null(manifest$files[[basename(test_file)]])) {
    file_status <- manifest$files[[basename(test_file)]]$status
    if (file_status == "protected") {
      cli::cli_alert_warning("Skipping protected file: {basename(test_file)}")
      return(invisible(NULL))
    }
  }

  # ... existing test generation code ...

  # Write to file
  writeLines(test_content, test_file)

  # UPDATE MANIFEST
  manifest$files[[basename(test_file)]] <- list(
    status = "generated",
    generated_date = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
  )
  manifest$updated <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
  write_test_manifest(manifest)

  cli::cli_alert_success("Generated {test_file}")
  invisible(test_file)
}

# Add manifest helpers:
read_test_manifest <- function() {
  manifest_path <- here::here("dev/test_manifest.json")
  if (!file.exists(manifest_path)) {
    return(list(version = "1.0", updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"), files = list()))
  }
  jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
}

write_test_manifest <- function(manifest) {
  jsonlite::write_json(
    manifest,
    here::here("dev/test_manifest.json"),
    pretty = TRUE,
    auto_unbox = TRUE
  )
}
```

### Workflow Integration
```yaml
# Source: schema-check.yml existing pattern
# Add after "Update documentation" step (line 192):

- name: Detect test gaps
  id: gaps
  if: steps.schema_changes.outputs.changed == 'true'
  continue-on-error: true
  run: |
    source("dev/detect_test_gaps.R")
  shell: Rscript {0}

- name: Generate missing tests
  id: tests
  if: steps.gaps.outputs.gaps_found == 'true'
  continue-on-error: true
  run: |
    source("dev/generate_tests.R")
  shell: Rscript {0}

# Modify "Calculate coverage" step to run after test generation:
- name: Calculate coverage
  id: coverage
  if: steps.schema_changes.outputs.changed == 'true'
  run: |
    source("dev/calculate_coverage.R")
  shell: Rscript {0}

# In "Prepare PR body" step, add test gaps section after stubs section:
- name: Prepare PR body
  id: pr_body
  if: steps.changes.outputs.has_changes == 'true'
  run: |
    # ... existing PR body template ...

    # Add test gaps section
    cat >> pr_body.md << 'TESTGAPS'

    ### Test Gaps & Generation
    TESTGAPS
    echo "- **Gaps Detected:** ${{ steps.gaps.outputs.gaps_count || '0' }}" >> pr_body.md
    echo "- **Tests Generated:** ${{ steps.tests.outputs.tests_generated || '0' }}" >> pr_body.md
    echo "- **Tests Skipped (Protected):** ${{ steps.tests.outputs.tests_skipped || '0' }}" >> pr_body.md
    echo "- **Gaps Remaining:** ${{ steps.tests.outputs.gaps_remaining || '0' }}" >> pr_body.md

    # ... continue with existing coverage section ...
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| set-output command | GITHUB_OUTPUT file | 2022 | Deprecated command; must use environment file |
| Manual test creation | Automated gap detection + generation | 2026 (this phase) | Reduces developer burden; ensures coverage |
| Hash-based staleness | Timestamp + manual review | 2026 (design decision) | Simpler maintenance; git provides audit trail |
| Separate workflows | Chained steps in single workflow | Current best practice | Single PR bundles all changes; easier review |

**Deprecated/outdated:**
- `::set-output name=key::value` syntax: Replaced by `echo "key=value" >> $GITHUB_OUTPUT` (https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/)
- Custom test coverage tools: R ecosystem standardized on covr package
- lintr for simple function detection: Overkill when base::parse() + all.names() suffices

## Open Questions

1. **JSON vs CSV for gap reports**
   - What we know: Both are readable; JSON better for nested data; CSV easier in spreadsheets
   - What's unclear: Which format better for CI tooling integration?
   - Recommendation: Use JSON (matches manifest format; easier to extend with nested metadata)

2. **Staleness threshold for protected files**
   - What we know: Protected files can become outdated if function signature changes
   - What's unclear: How aggressive should warnings be? (every run vs weekly digest)
   - Recommendation: Flag staleness in gap report but don't block CI; developer decides when to update

3. **Handling multi-function files**
   - What we know: Some R files contain multiple exported functions (less common in this codebase)
   - What's unclear: Should gap detector handle 1:many file:function mappings?
   - Recommendation: Scope to 1:1 mapping (current codebase pattern); defer complex cases to Phase 26+ if needed

## Sources

### Primary (HIGH confidence)
- [GitHub Actions GITHUB_OUTPUT Documentation](https://docs.github.com/actions/writing-workflows/choosing-what-your-workflow-does/passing-information-between-jobs) - Official docs on step outputs
- [GitHub Actions Deprecating set-output](https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/) - Migration from deprecated commands
- [R parse() Documentation](https://search.r-project.org/CRAN/refmans/testthat/testthat.pdf) - AST parsing capabilities (verified January 2026)
- [rsconnect manifest.json](https://docs.posit.co/connect/user/manifest/) - JSON manifest pattern in R ecosystem (Posit Connect 2026.01.1)
- Existing codebase: `dev/generate_tests.R`, `dev/endpoint_eval/03_codebase_search.R`, `.github/workflows/schema-check.yml`

### Secondary (MEDIUM confidence)
- [lintr Static Code Analysis for R](https://lintr.r-lib.org/) - Alternative AST parsing approach (not needed for this use case)
- [GitHub Actions Test Reporter](https://github.com/marketplace/actions/test-reporter) - Community pattern for test reporting in workflows
- [R covr Package](https://covr.r-lib.org/) - Standard tool for test coverage analysis
- [Using Parse Data to Analyze R Code](https://renkun.me/2020/11/08/using-parse-data-to-analyze-r-code/) - Tutorial on R AST parsing techniques

### Tertiary (LOW confidence)
- WebSearch results on R package testing automation (2026) - General discussion, no specific tools identified
- WebSearch results on static code analysis ASTs - Generic programming concepts, not R-specific

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools are native R or already in project dependencies
- Architecture: HIGH - Existing patterns in schema-check.yml provide clear template
- Pitfalls: HIGH - Based on direct examination of codebase patterns and common GitHub Actions issues
- Gap detection logic: HIGH - Native R parse() is well-documented and battle-tested
- Manifest design: MEDIUM - Simple design based on Posit Connect pattern; not yet validated in practice

**Research date:** 2026-02-28
**Valid until:** 2026-04-28 (60 days - stable R ecosystem and GitHub Actions APIs)
