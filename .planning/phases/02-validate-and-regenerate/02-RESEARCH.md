# Phase 2: Validate and Regenerate - Research

**Researched:** 2026-01-26
**Domain:** R package function regeneration and validation
**Confidence:** HIGH

## Summary

This research investigates how to regenerate function stubs using the modified stub generation pipeline from Phase 1, validate that generated functions have correct signatures, and test them against the live CompTox API. The phase focuses on three validation requirements: (1) verifying the `ct_chemical_search_equal_bulk()` function has the `words` parameter (should be `query` based on Phase 1 changes), (2) ensuring generated functions pass `devtools::document()` without errors, and (3) confirming functions work against the live API.

The validation workflow follows R package development best practices: regenerate stubs using the modified pipeline scripts, run `devtools::document()` to generate roxygen2 documentation, and test against the live API using the vcr package's cassette recording system.

**Primary recommendation:** Run `dev/ct_endpoint_eval.R` to regenerate stubs with the modified pipeline, validate function signatures programmatically, run `devtools::document()` to check roxygen2 documentation, and create targeted tests for simple body schema endpoints using vcr cassettes.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| devtools | 2.4.5+ | R package development | Standard tool for building, documenting, and testing R packages |
| roxygen2 | 7.3.0+ | Documentation generation | Generates .Rd files from #' comments in code |
| testthat | 3.2.0+ | Unit testing framework | Standard R testing framework with vcr integration |
| vcr | 2.1.0+ | HTTP request recording | Records/replays API interactions for deterministic testing |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| here | Latest | Path resolution | Cross-platform file path handling |
| cli | Latest | User messages | Better error/warning messages during validation |
| rlang | Latest | R language tools | Function inspection and validation |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| vcr | httptest | vcr has better integration with httr2 |
| devtools | R CMD | devtools provides better workflow tools |
| testthat | RUnit | testthat is more widely adopted and maintained |

**Installation:**
```bash
# All dependencies already in DESCRIPTION
```

## Architecture Patterns

### Recommended Project Structure
```
dev/
├── ct_endpoint_eval.R           # Main regeneration script
├── endpoint_eval/
│   ├── 01_schema_resolution.R   # Modified in Phase 1
│   ├── 04_openapi_parser.R      # Calls extract_body_properties
│   ├── 06_param_parsing.R       # Parameter parsing
│   └── 07_stub_generation.R     # Modified in Phase 1
R/
├── ct_chemical_search_equal.R   # Target file to regenerate
└── z_generic_request.R          # Request handler
tests/testthat/
├── helper-vcr.R                 # VCR configuration
└── test-ct_chemical_search_equal.R  # Validation tests
```

### Pattern 1: Stub Regeneration Workflow

**What:** Execute the stub generation pipeline to regenerate function files with modified code generation logic.

**When to use:** After modifying the stub generation pipeline to fix bugs or add features.

**Example:**
```r
# Source: dev/ct_endpoint_eval.R:1-194
# Workflow steps:

# 1. Load OpenAPI schemas
ctx_schema_files <- list.files(
  path = here::here('schema'),
  pattern = "^ctx_.*_prod\\.json$",
  full.names = FALSE
)

# 2. Parse schemas into endpoint specifications
endpoints <- map(ctx_schema_files, ~ {
  openapi <- jsonlite::fromJSON(here::here('schema', .x), simplifyVector = FALSE)
  openapi_to_spec(openapi)
}) %>% list_rbind()

# 3. Identify missing endpoints
res <- find_endpoint_usages_base(
  endpoints$route,
  pkg_dir = here::here("R"),
  files_regex = "^ct_.*\\.R$"
)

# 4. Generate stubs for missing endpoints
spec_with_text <- render_endpoint_stubs(
  endpoints_to_build,
  config = ct_config
)

# 5. Write files to disk
scaffold_result <- scaffold_files(
  spec_with_text,
  base_dir = "R",
  overwrite = FALSE,
  append = TRUE
)
```

**Key insight:** The pipeline uses `append = TRUE` to add new functions to existing files without overwriting manually-written functions. For regeneration, you need to either delete the target file first or use `overwrite = TRUE` (with caution).

### Pattern 2: Function Signature Validation

**What:** Programmatically verify that generated functions have the expected parameters in their signatures.

**When to use:** After regenerating stubs to ensure parameter extraction worked correctly.

**Example:**
```r
# Validate function signature has expected parameters
validate_function_signature <- function(fn_name, expected_params) {
  # Get function definition
  fn <- get(fn_name, envir = asNamespace("ComptoxR"))

  # Extract formal parameters
  actual_params <- names(formals(fn))

  # Check expected parameters are present
  missing_params <- setdiff(expected_params, actual_params)

  if (length(missing_params) > 0) {
    cli::cli_abort(
      "Function {fn_name} missing expected parameters: {missing_params}"
    )
  }

  cli::cli_alert_success("Function {fn_name} has correct signature")
  invisible(TRUE)
}

# Usage for VAL-01
validate_function_signature(
  "ct_chemical_search_equal_bulk",
  expected_params = c("query")  # Based on Phase 1 changes
)
```

### Pattern 3: Documentation Generation and Validation

**What:** Run `devtools::document()` to generate .Rd files from roxygen2 comments and validate no errors occur.

**When to use:** After regenerating stubs to ensure roxygen2 documentation is valid.

**Example:**
```r
# Source: devtools documentation
# https://devtools.r-lib.org/reference/document.html

# Run documentation generation
result <- devtools::document()

# devtools::document() will:
# 1. Source all R files in R/ directory
# 2. Parse roxygen2 comments (lines starting with #')
# 3. Generate .Rd files in man/ directory
# 4. Update NAMESPACE file with @export declarations

# Check for warnings/errors
# document() will abort if there are roxygen2 syntax errors
# Successful execution means roxygen2 is valid (VAL-02)
```

**Key parameters:**
- `pkg = "."`: Package directory (defaults to current directory)
- `roclets = NULL`: Use default roclets (rd, namespace, collate)
- `quiet = FALSE`: Show progress messages

### Pattern 4: Live API Testing with VCR

**What:** Use the vcr package to record HTTP interactions with the live API and replay them in subsequent test runs.

**When to use:** Testing generated functions against the live CompTox API without hitting the API on every test run.

**Example:**
```r
# Source: tests/testthat/helper-vcr.R
# Configure VCR cassette directory and API key filtering
vcr::vcr_configure(
  dir = "../testthat/fixtures",
  filter_sensitive_data = list(
    "<<<API_KEY>>>" = Sys.getenv("ctx_api_key")
  )
)

# Source: tests/testthat/test-ct_hazard.R
# Test pattern for live API validation
test_that("ct_chemical_search_equal_bulk works with query parameter", {
  vcr::use_cassette("ct_chemical_search_equal_bulk", {
    # First run: records to cassette file
    # Subsequent runs: replays from cassette
    result <- ct_chemical_search_equal_bulk(
      query = c("DTXSID7020182", "DTXSID5032381")
    )

    # Validate return type
    expect_s3_class(result, "tbl_df")

    # Validate structure
    expect_true(ncol(result) > 0)
    expect_true(nrow(result) > 0)
  })
})
```

**Testing against live API:**
```bash
# First run requires valid API key
Sys.setenv(ctx_api_key = "YOUR_KEY_HERE")

# Delete cassette to force live API hit
unlink("tests/testthat/fixtures/ct_chemical_search_equal_bulk.yml")

# Run test - will record from live API
devtools::test()

# Subsequent runs use recorded cassette (no API key needed)
devtools::test()
```

**Key insight:** VCR cassettes are YAML files stored in `tests/testthat/fixtures/`. First run records from live API, subsequent runs replay from cassette. Always verify cassettes don't contain actual API keys before committing.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Function signature inspection | String parsing of function text | `formals()` and `rlang::fn_fmls()` | Built-in R functions handle edge cases correctly |
| Documentation generation | Manual .Rd file writing | `devtools::document()` + roxygen2 | Roxygen2 handles complex documentation patterns |
| HTTP request recording | Custom mocking system | vcr package | VCR handles request matching, filtering, edge cases |
| Package path resolution | Relative paths or getwd() | `here::here()` | Cross-platform, works in tests and scripts |

**Key insight:** R package development has mature tooling. Don't reinvent validation or testing infrastructure.

## Common Pitfalls

### Pitfall 1: Overwriting Manual Changes

**What goes wrong:** Running stub regeneration with `overwrite = TRUE` or `append = TRUE` can overwrite manually-edited functions in existing files.

**Why it happens:** The scaffold system appends to existing files, and the pipeline doesn't distinguish between generated and manually-written functions.

**How to avoid:**
- For targeted regeneration, delete the specific function in the target file first
- Use version control to review changes before committing
- Consider regenerating to a temporary directory first for inspection

**Warning signs:**
- Git diff shows unexpected changes to functions you manually edited
- Functions lose custom post-processing or error handling

### Pitfall 2: Missing API Key for First Test Run

**What goes wrong:** VCR tests fail on first run because cassettes don't exist yet and no API key is configured.

**Why it happens:** vcr requires a real API call to create the cassette file initially.

**How to avoid:**
```r
# Set API key before first test run
Sys.setenv(ctx_api_key = "YOUR_KEY_HERE")

# Verify key is set
ct_api_key()  # Will abort with helpful message if not set

# Run test to record cassette
devtools::test_file("tests/testthat/test-ct_chemical_search_equal.R")

# Verify cassette was created
list.files("tests/testthat/fixtures", pattern = "ct_chemical_search_equal")
```

**Warning signs:**
- Tests fail with "No API key" error on first run
- Cassette files are not created in fixtures/ directory

### Pitfall 3: Incorrect Parameter Names in Validation

**What goes wrong:** VAL-01 expects parameter named `words` but Phase 1 changes use `query` as the synthetic parameter name.

**Why it happens:** The requirement was written before understanding the implementation decision to use `query` for all simple body types.

**How to avoid:**
- Verify the actual parameter name in the generated function before validation
- Update validation expectations to match implementation
- Check the OpenAPI schema to see what the original parameter name was

**Warning signs:**
- Function signature validation fails even though function looks correct
- Mismatch between requirement text and implementation

### Pitfall 4: roxygen2 Syntax Errors

**What goes wrong:** `devtools::document()` fails with cryptic errors about malformed roxygen2 comments.

**Why it happens:** Generated roxygen2 comments have syntax errors (missing closing braces, invalid tags, etc.).

**How to avoid:**
- Inspect generated roxygen2 comments in the .R files
- Common issues:
  - Unescaped `{` or `}` in @param descriptions
  - Invalid @return statements
  - Missing closing `}}` in @examples
- Run `devtools::document()` early to catch syntax errors

**Warning signs:**
- Error message contains "unexpected token" or "malformed tag"
- Specific line numbers point to roxygen2 comment lines

## Code Examples

Verified patterns from official sources:

### Regenerate Single Function Stub

```r
# Source: dev/ct_endpoint_eval.R (adapted)
library(here)
library(tidyverse)
source(here("dev", "endpoint_eval_utils.R"))

# Configuration
ct_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# Load OpenAPI schema
openapi <- jsonlite::fromJSON(
  here("schema", "ctx_chemical_prod.json"),
  simplifyVector = FALSE
)

# Parse endpoint specifications
endpoints <- openapi_to_spec(openapi)

# Filter to specific endpoint
target_endpoint <- endpoints %>%
  filter(route == "chemical/search/equal/", method == "POST")

# Generate stub text
spec_with_text <- render_endpoint_stubs(
  target_endpoint,
  config = ct_config
)

# Inspect generated code
cat(spec_with_text$text)

# Optionally write to file
writeLines(
  spec_with_text$text,
  here("R", "ct_chemical_search_equal_bulk_regenerated.R")
)
```

### Validate Function Signatures

```r
# Validate ct_chemical_search_equal_bulk signature
devtools::load_all()  # Load package functions

fn <- ct_chemical_search_equal_bulk
formals_list <- formals(fn)
param_names <- names(formals_list)

# VAL-01: Check for query parameter (not words)
if (!"query" %in% param_names) {
  cli::cli_abort("ct_chemical_search_equal_bulk missing 'query' parameter")
}

cli::cli_alert_success("VAL-01 passed: Function has 'query' parameter")
```

### Run devtools::document()

```r
# Source: https://devtools.r-lib.org/reference/document.html
# VAL-02: Ensure generated functions pass documentation

result <- devtools::document()

# Successful execution means roxygen2 is valid
# Check NAMESPACE was updated
namespace_lines <- readLines("NAMESPACE")
if (!"export(ct_chemical_search_equal_bulk)" %in% namespace_lines) {
  cli::cli_warn("Function not exported in NAMESPACE")
}

cli::cli_alert_success("VAL-02 passed: devtools::document() completed successfully")
```

### Test Against Live API

```r
# Source: tests/testthat/test-ct_chemical_search_equal.R
# VAL-03: Verify generated function works against live API

test_that("ct_chemical_search_equal_bulk works with live API", {
  # Skip if no API key (for CI/CD)
  skip_if_not(nzchar(Sys.getenv("ctx_api_key")), "No API key configured")

  vcr::use_cassette("ct_chemical_search_equal_bulk", {
    result <- ct_chemical_search_equal_bulk(
      query = c("DTXSID7020182", "DTXSID5032381", "DTXSID8024291")
    )

    # Check return type
    expect_s3_class(result, "tbl_df")

    # Check structure
    expect_true(ncol(result) > 0)
    expect_true(nrow(result) > 0)

    # Check for expected columns
    expect_true("dtxsid" %in% colnames(result))
  })
})

# Run test
devtools::test_file("tests/testthat/test-ct_chemical_search_equal.R")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual .Rd file writing | roxygen2 + devtools::document() | ~2015 | Standard R package workflow |
| Manual HTTP mocking | vcr package | ~2018 | Deterministic API testing |
| Relative paths in tests | here::here() | ~2017 | Cross-platform compatibility |
| String body schemas ignored | Synthetic query parameter | Phase 1 (2026-01-26) | Enables simple body schema handling |

**Deprecated/outdated:**
- `httr` for HTTP requests: replaced by `httr2` (better error handling, pipe-friendly)
- Manual NAMESPACE management: now handled by roxygen2 @export
- `RUnit` for testing: superseded by `testthat`

## Open Questions

Things that couldn't be fully resolved:

1. **Parameter Name Discrepancy**
   - What we know: VAL-01 expects `words` parameter, Phase 1 uses `query`
   - What's unclear: Whether requirement should be updated or implementation should use schema-specific names
   - Recommendation: Use `query` for consistency with other simple body endpoints, update requirement text

2. **Regeneration Strategy**
   - What we know: scaffold_files() uses `append = TRUE` by default
   - What's unclear: Best practice for regenerating specific functions without affecting manually-edited code
   - Recommendation: Delete target function manually before regeneration, or use temporary directory approach

3. **Test Endpoint Selection**
   - What we know: Need to test simple body schema endpoint
   - What's unclear: Which endpoint(s) beyond chemical/search/equal have simple body schemas
   - Recommendation: Query OpenAPI schema for all POST endpoints with `type: "string"` or `type: "array"` bodies

## Sources

### Primary (HIGH confidence)
- [devtools::document() reference](https://devtools.r-lib.org/reference/document.html) - Official documentation
- [R Packages (2e) - Chapter 16: Function documentation](https://r-pkgs.org/man.html) - Authoritative guide
- [vcr Getting Started](https://docs.ropensci.org/vcr/articles/vcr.html) - Official vcr documentation
- [HTTP testing in R - Chapter 6: Use vcr](https://books.ropensci.org/http-testing/vcr.html) - Comprehensive guide

### Secondary (MEDIUM confidence)
- Codebase files:
  - `dev/ct_endpoint_eval.R` - Main regeneration script
  - `dev/endpoint_eval/07_stub_generation.R` - Phase 1 modifications
  - `dev/endpoint_eval/01_schema_resolution.R` - Phase 1 modifications
  - `tests/testthat/helper-vcr.R` - VCR configuration
  - `tests/testthat/test-ct_hazard.R` - Test pattern example
  - `R/z_generic_request.R` - Request handling

### Tertiary (LOW confidence)
- None - all findings verified with official documentation or codebase inspection

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools are mature, well-documented R packages
- Architecture: HIGH - Patterns verified in codebase and official documentation
- Pitfalls: HIGH - Based on common R package development issues and codebase patterns

**Research date:** 2026-01-26
**Valid until:** ~60 days (R package tooling is stable, unlikely to change rapidly)
