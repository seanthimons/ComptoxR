# Phase 23: Build Fixes & Test Generator Core - Research

**Researched:** 2026-02-27
**Domain:** R package development, automated code generation, test infrastructure
**Confidence:** HIGH

## Summary

This phase fixes critical R package build errors and rebuilds the test generator to produce correct, type-aware tests. The work falls into three distinct technical domains: (1) R CMD check compliance fixes (syntax errors, licensing, encoding, imports), (2) test generator metadata extraction and type mapping, and (3) schema automation pipeline alignment.

The build errors are straightforward fixes—most are caused by stub generator bugs producing invalid R syntax (`"RF" <- model = "RF"`), roxygen mismatches, and dependency configuration issues. The test generator rebuild is more complex: it currently blindly passes DTXSIDs to all parameters and assumes all functions return tibbles, causing 834+ test failures. The fixed generator must read actual function signatures using `formals()`, extract the `tidy` flag from function bodies, and map parameter names to appropriate test values.

Schema automation Items 2 & 3 add drift detection and align schema selection between the diff reporter and stub generator, ensuring both tools operate on the same canonical schemas per API domain.

**Primary recommendation:** Fix non-generator BUILD issues first (BUILD-02 through BUILD-08), then fix the generator pipeline (BUILD-01 + Items 2 & 3), regenerate all stubs cleanly, and run R CMD check to verify.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Build fix ordering and strategy:**
- Merge the open PR first to get up-to-date schemas locally
- Fix non-generator BUILD issues first (BUILD-02 through BUILD-08) before touching the generator
- Then fix the generator pipeline itself (BUILD-01 syntax bugs + Items 2 & 3)
- Purge experimental stubs using existing scripts, then regenerate all stubs from the fixed generator
- Final R CMD check should be clean after regeneration

**License (BUILD-07):**
- Use MIT + file LICENSE
- Run `usethis::use_mit_license()` to set up properly

**Schema automation pipeline (Items 2 & 3):**
- Item 2: Move `select_schema_files()` to shared utility, align diff reporter and stub generator on same schema selection
- Item 3: Add `detect_parameter_drift()` as report-only (no auto-modification of existing functions)
- Both items included in Phase 23 with tests, clearly defined as separate work units
- Follow the design in SCHEMA_AUTOMATION_PLAN.md (Approach A for Item 2)

**Test generator depth:**
- Smoke tests + type checks: verify function runs without error, returns correct type (tibble vs list), has expected column names
- No comprehensive value assertions (too brittle with changing API responses)

**Test variants per function:**
- **single** — one valid input, VCR cassette recorded
- **batch** — vector of 2-3 valid inputs, VCR cassette recorded
- **error** — missing required params, pure R check, no cassette needed
- API error response variants (invalid input -> HTTP error) deferred to Phase 24 when cassettes are clean

**Test fixture value resolution:**
- Priority 1: Use values from roxygen `@examples` if the function has examples filled out
- Priority 2: Fall back to explicit mapping table of parameter-name-to-default-value
- Canonical fallback DTXSID: DTXSID7020182 (Bisphenol A)
- Mapping table covers: formula, SMILES, CAS, list names, AEIDs, and other parameter types
- Batch tests use 2-3 items (small enough for compact cassettes, large enough to verify batching)

### Claude's Discretion

- Exact parameter-to-value mapping table entries (beyond the canonical DTXSID)
- How to detect which stubs have manual edits vs pure generated code
- Implementation details of `detect_parameter_drift()` (parse-based vs regex-based formals extraction)
- Ordering of individual BUILD-02 through BUILD-08 fixes within the "before regeneration" group
- httr2 compatibility resolution approach (BUILD-05: update minimum version vs replace missing functions)

### Deferred Ideas (OUT OF SCOPE)

- API error response test variants (invalid input -> HTTP errors with cassettes) — Phase 24 when cassette infrastructure is clean
- Auto-updating experimental lifecycle stubs based on drift detection — future enhancement after drift reporting is proven
- Scheduled/automated cassette re-recording — Phase 24
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BUILD-01 | R CMD check produces 0 errors after fixing stub generator syntax bugs | Stub generation code patterns, glue template escaping |
| BUILD-02 | All unused/undeclared imports resolved | DESCRIPTION dependency management, Imports vs Suggests |
| BUILD-03 | Non-ASCII characters replaced with `\uxxxx` escapes | `stringi::stri_escape_unicode()`, R CMD check portable encoding requirements |
| BUILD-04 | `jsonlite::flatten` vs `purrr::flatten` import collision resolved | NAMESPACE import precedence, explicit package prefixes |
| BUILD-05 | httr2 compatibility fixed | httr2 version comparison, custom helper vs version bump |
| BUILD-06 | Roxygen `@param` documentation matches function signatures | roxygen2 documentation patterns, `devtools::document()` workflow |
| BUILD-07 | Non-standard license replaced with valid CRAN spec | `usethis::use_mit_license()`, CRAN license requirements |
| BUILD-08 | Partial argument match `body` → `body_type` fixed | Full parameter name specification in function calls |
| TGEN-01 | Test generator reads parameter names and types from function signatures | `formals()`, `rlang::fn_fmls()`, parameter name-to-type mapping |
| TGEN-02 | Test generator reads `tidy` flag from function bodies | Parse function source, regex extraction of `tidy = TRUE/FALSE` |
| TGEN-03 | Test generator handles functions with no parameters | Static endpoint detection, parameterless test call generation |
| TGEN-04 | Test generator handles functions with `path_params` | Multi-parameter path-based endpoints, parameter name mapping |
| TGEN-05 | Generated tests use unique cassette names per variant | VCR cassette naming conventions, variant suffixes (_single, _batch, _error) |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| devtools | Any | Package development workflow | R community standard for package dev |
| testthat | >= 3.0.0 | Test framework | CRAN standard, edition 3 for snapshot tests |
| vcr | Latest | HTTP request recording/replay | Standard for API wrapper testing in R |
| roxygen2 | 7.3.3 | Documentation generation | CRAN standard for inline documentation |
| usethis | Latest | Package setup automation | R-lib standard for package scaffolding |
| httr2 | Latest | HTTP client | Modern R HTTP library (successor to httr) |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| stringi | Any | Unicode escaping | Fixing non-ASCII characters (BUILD-03) |
| rlang | Latest | Function introspection | Extracting formals with `fn_fmls()` |
| glue | Latest | String templating | Code generation with variable interpolation |
| jsonlite | >= 1.8.8 | JSON parsing | Schema parsing, API responses |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| testthat | RUnit, tinytest | testthat is CRAN standard, better snapshot support |
| vcr | httptest2, webmockr | vcr is standard for API wrappers, simpler setup |
| roxygen2 | inlinedocs, document | roxygen2 is CRAN requirement for modern packages |

**Installation:**

Already in DESCRIPTION. For manual testing:
```r
install.packages(c("devtools", "testthat", "vcr", "roxygen2", "usethis", "stringi", "rlang"))
```

## Architecture Patterns

### Recommended Project Structure

Current structure is correct:
```
R/
├── z_generic_request.R         # Request templates
├── ct_*.R                       # CompTox Dashboard wrappers
├── chemi_*.R                    # Cheminformatics wrappers
└── extract_mol_formula.R        # Contains non-ASCII characters

dev/
├── endpoint_eval/
│   ├── 00_config.R
│   ├── 01_schema_resolution.R  # Move select_schema_files() here (Item 2)
│   ├── 07_stub_generation.R    # Contains build_function_stub()
│   └── 08_drift_detection.R    # NEW: detect_parameter_drift() (Item 3)
├── generate_stubs.R             # Main stub generator entry point
└── diff_schemas.R               # Schema diff reporter (Item 2)

tests/testthat/
├── helper-vcr.R                 # VCR configuration
├── test-*.R                     # Auto-generated tests
└── fixtures/                    # VCR cassettes
```

### Pattern 1: Function Signature Extraction (TGEN-01)

**What:** Extract formal parameters from a function definition in an R source file.

**When to use:** Test generator needs to read actual parameter names and types from generated stubs.

**Example:**
```r
# Using base R parse + formals
extract_function_formals <- function(file_path, function_name) {
  expr <- parse(file = file_path)

  # Find function assignments
  for (e in expr) {
    if (is.call(e) && identical(e[[1]], as.name("<-"))) {
      if (identical(e[[2]], as.name(function_name))) {
        fn <- eval(e[[3]])
        return(formals(fn))
      }
    }
  }

  NULL
}

# Using rlang (more robust)
library(rlang)
fn <- source_function_from_file(file_path, function_name)
params <- fn_fmls_names(fn)  # Returns character vector of param names
```

**Source:** [R-hub blog: Code generation in R packages](https://blog.r-hub.io/2020/02/10/code-generation/), [rlang::fn_fmls()](https://rlang.r-lib.org/reference/fn_fmls.html)

### Pattern 2: Extracting tidy Flag from Function Body (TGEN-02)

**What:** Parse function source code to detect `tidy = TRUE/FALSE` in `generic_request()` calls.

**When to use:** Test generator needs to assert correct return type (tibble vs list).

**Example:**
```r
extract_tidy_flag <- function(file_path) {
  lines <- readLines(file_path)

  # Find lines with generic_request or generic_chemi_request calls
  request_lines <- grep("generic_(request|chemi_request|cc_request)", lines, value = TRUE)

  # Extract tidy parameter
  for (line in request_lines) {
    if (grepl("tidy\\s*=\\s*(TRUE|FALSE)", line)) {
      match <- regmatches(line, regexpr("tidy\\s*=\\s*(TRUE|FALSE)", line))
      return(grepl("TRUE", match))
    }
  }

  # Default to TRUE if not specified
  TRUE
}
```

**Source:** Pattern from existing codebase

### Pattern 3: Parameter Name to Test Value Mapping (TGEN-01, TGEN-04)

**What:** Map parameter names to appropriate test values by type.

**When to use:** Test generator needs to pass correct types (DTXSID for query, integer for limit, etc.).

**Example:**
```r
# Mapping table
param_to_test_value <- list(
  # Identifiers
  "query" = "DTXSID7020182",
  "dtxsid" = "DTXSID7020182",
  "dtxcid" = "DTXCID7020182",
  "casrn" = "80-05-7",
  "cas" = "80-05-7",
  "smiles" = "c1ccccc1",
  "inchi" = "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H",

  # Numeric parameters
  "limit" = 100L,
  "offset" = 0L,
  "page" = 1L,
  "top" = 10L,
  "skip" = 0L,

  # String parameters
  "search_type" = "equals",
  "list_name" = "PRODWATER",
  "domain" = "hazard",

  # Property parameters
  "formula" = "C15H14O",
  "mass" = 210.0,

  # Boolean
  "tidy" = TRUE,
  "verbose" = FALSE
)

get_test_value <- function(param_name) {
  # Try exact match
  if (param_name %in% names(param_to_test_value)) {
    return(param_to_test_value[[param_name]])
  }

  # Try pattern matching
  if (grepl("limit|count|size|top", param_name, ignore.case = TRUE)) {
    return(100L)
  }
  if (grepl("offset|skip|start", param_name, ignore.case = TRUE)) {
    return(0L)
  }

  # Default to canonical DTXSID
  "DTXSID7020182"
}
```

**Source:** Derived from existing test patterns and API documentation

### Pattern 4: VCR Cassette Configuration (TGEN-05)

**What:** Configure VCR to record HTTP interactions with API key filtering.

**When to use:** All tests that hit external APIs.

**Example:**
```r
# In tests/testthat/helper-vcr.R (existing)
library(vcr)

vcr_dir <- "../testthat/fixtures"
if (!dir.exists(vcr_dir)) dir.create(vcr_dir, recursive = TRUE)

vcr::vcr_configure(
  dir = vcr_dir,
  filter_sensitive_data = list(
    "<<<API_KEY>>>" = Sys.getenv("ctx_api_key")
  )
)

# In tests
test_that("function works", {
  vcr::use_cassette("function_name_single", {
    result <- ct_function("DTXSID7020182")
    expect_s3_class(result, "tbl_df")
  })
})
```

**Source:** [vcr vignette](https://docs.ropensci.org/vcr/articles/vcr.html), [HTTP testing in R book](https://books.ropensci.org/http-testing/vcr.html)

### Pattern 5: Unicode Escape Conversion (BUILD-03)

**What:** Replace non-ASCII characters with `\uxxxx` escapes for R CMD check compliance.

**When to use:** Any R source file with non-ASCII characters (e.g., middle dot ·, en dash –).

**Example:**
```r
# Before (causes R CMD check WARNING)
elements_list <- c('He','Li','Be','Ne','Na','Mg','Al')  # Contains '·' somewhere

# After (portable)
# Use stringi to convert
library(stringi)
text <- "middle dot: ·"
escaped <- stri_escape_unicode(text)
# Result: "middle dot: \\u00b7"

# Or manually:
candidate_regex <- "(\\([A-Za-z0-9+\\-\\.\\u00b7\\s]*\\))"  # \u00b7 = middle dot
```

**Source:** [GitHub discussion on non-ASCII characters](https://github.com/ThinkR-open/golem/discussions/659), [R tools showNonASCII](https://rdrr.io/r/tools/showNonASCII.html)

### Pattern 6: License Specification (BUILD-07)

**What:** Set up CRAN-compliant license using usethis helpers.

**When to use:** Fixing non-standard license in DESCRIPTION.

**Example:**
```r
# For MIT license
usethis::use_mit_license()
# Creates LICENSE file, updates DESCRIPTION to "License: MIT + file LICENSE"

# For GPL-3
usethis::use_gpl3_license()
# Updates DESCRIPTION to "License: GPL-3"

# NEVER use placeholder syntax like this in DESCRIPTION:
# License: `use_mit_license()`, `use_gpl3_license()`  # WRONG
```

**Source:** [R packages book chapter on licensing](https://r-pkgs.org/license.html), [usethis licenses reference](https://usethis.r-lib.org/reference/licenses.html)

### Anti-Patterns to Avoid

- **Don't assume parameter types from names alone:** Always read function signatures; "query" could be DTXSID, SMILES, or formula depending on endpoint.
- **Don't hardcode API keys in tests:** Always use VCR filtering with `filter_sensitive_data`.
- **Don't regenerate stubs before fixing the generator:** BUILD-01 syntax bugs will propagate to all regenerated files.
- **Don't use placeholder license syntax:** `use_mit_license()` is a function call, not a license string.
- **Don't manually edit VCR cassettes without understanding the consequences:** First run records from production; subsequent runs replay cassettes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Unicode character escaping | Manual `\u` conversion | `stringi::stri_escape_unicode()` | Automated, handles all Unicode ranges correctly |
| License file creation | Manual LICENSE text | `usethis::use_mit_license()` | CRAN-compliant format, updates DESCRIPTION automatically |
| Function signature extraction | Regex parsing of R code | `formals()` or `rlang::fn_fmls()` | Handles edge cases (defaults, ellipsis, special characters) |
| HTTP request recording | Custom mock infrastructure | vcr package | Standard in R ecosystem, battle-tested, API key filtering |
| Roxygen documentation | Manual .Rd files | roxygen2 with `@param` tags | CRAN standard, auto-syncs docs with code |

**Key insight:** R package tooling is mature and standardized. Custom solutions for these problems add maintenance burden and CRAN compliance risk.

## Common Pitfalls

### Pitfall 1: Invalid R Syntax in Generated Code (BUILD-01)

**What goes wrong:** Stub generator produces `"RF" <- model = "RF"` which is syntactically invalid R. This happens in `build_function_stub()` when building the `options` list for chemi functions.

**Why it happens:** String templating with glue doesn't escape or validate R syntax. The template line:
```r
if (!is.null(model = "RF")) options$model = "RF" <- model = "RF"
```
appears to be a glue template error where variable substitution went wrong.

**How to avoid:**
1. Use proper glue syntax: `{var}` not bare `var`
2. Validate generated code: `parse(text = generated_code)` before writing
3. Add unit tests for stub generator with known inputs
4. Review generated stubs before committing

**Warning signs:**
- R CMD check fails with "unexpected symbol" or "unexpected '<-'"
- Generated functions have syntax highlighting errors
- `devtools::load_all()` fails to parse R/ files

### Pitfall 2: Roxygen @param Mismatch (BUILD-06)

**What goes wrong:** Function signature has `smiles, model` but roxygen docs have `@param chemicals`, causing R CMD check WARNING.

**Why it happens:** Stub generator copies @param tags from schema descriptions without validating against actual function signature. Parameter names in schema may differ from function parameter names.

**How to avoid:**
1. Always generate @param tags from actual function `formals()`, not schema
2. Run `devtools::document()` after stub generation
3. Check for mismatches: `tools::checkDocFiles("path/to/package")`

**Warning signs:**
- R CMD check: "Documented arguments not in \usage"
- R CMD check: "Undocumented arguments"
- Help pages show parameters that don't exist

### Pitfall 3: Test Type Assertion Mismatch (TGEN-02)

**What goes wrong:** Function has `tidy = FALSE` (returns list) but test asserts `expect_s3_class(result, "tbl_df")`, causing 122+ test failures.

**Why it happens:** Test generator assumes all functions return tibbles without reading actual `tidy` flag from function body.

**How to avoid:**
1. Parse function source to extract `tidy` parameter value
2. Generate assertions based on actual return type:
   - `tidy = TRUE` → `expect_s3_class(result, "tbl_df")`
   - `tidy = FALSE` → `expect_type(result, "list")`
3. Handle missing `tidy` (default TRUE for generic_request)

**Warning signs:**
- Batch test failures with "inherits(result, 'tbl_df') is not TRUE"
- Tests pass for some functions, fail for others with same pattern
- Manual function calls work but tests fail

### Pitfall 4: Wrong Parameter Types in Tests (TGEN-01)

**What goes wrong:** Test generator passes `limit = "DTXSID7020182"` causing API errors or R type errors.

**Why it happens:** Generator blindly uses first parameter as DTXSID query without inspecting parameter names or types.

**How to avoid:**
1. Build parameter name → test value mapping table
2. Inspect function signature with `formals()`
3. Match parameter name patterns (limit → integer, query → DTXSID, etc.)
4. Fall back to roxygen @examples if available

**Warning signs:**
- Tests fail with "invalid type, expected integer"
- VCR cassettes record API 400 errors
- Tests work for some functions, fail for others with different param names

### Pitfall 5: Partial Argument Matching (BUILD-08)

**What goes wrong:** R CMD check WARNING: "partial argument match of 'body' to 'body_type'".

**Why it happens:** Function call uses abbreviated parameter name `body` when full name is `body_type`. R's partial matching allows this but CRAN flags it as bad practice.

**How to avoid:**
1. Always use full parameter names in function calls
2. Run R CMD check locally before committing
3. Search for abbreviated params: `grep -r "body =" R/`

**Warning signs:**
- R CMD check: "partial argument match"
- Code works but generates warnings
- Multiple similar warnings for same parameter

### Pitfall 6: VCR Cassette Naming Collisions (TGEN-05)

**What goes wrong:** Multiple test variants (single, batch, error) use same cassette name, overwriting each other's recordings.

**Why it happens:** Generator uses base function name without variant suffix.

**How to avoid:**
1. Append variant suffix: `function_name_single`, `function_name_batch`, `function_name_error`
2. Use unique cassette per test block
3. Document naming convention in helper-vcr.R

**Warning signs:**
- Re-recording cassettes changes unrelated tests
- Tests pass individually but fail in batch
- Cassette contents don't match test expectations

## Code Examples

Verified patterns from codebase and documentation:

### Extracting Function Formals

```r
# Source: dev/endpoint_eval/08_drift_detection.R (to be created)

#' Extract function parameter names from R source file
#' @param file_path Path to .R file
#' @param function_name Name of function to extract
#' @return Named list of formal parameters
extract_function_params <- function(file_path, function_name) {
  tryCatch({
    # Parse the file
    expr <- parse(file = file_path)

    # Find function assignment
    for (e in expr) {
      if (is.call(e) && identical(e[[1]], as.name("<-"))) {
        lhs <- e[[2]]
        rhs <- e[[3]]

        if (identical(lhs, as.name(function_name)) && is.call(rhs)) {
          # Extract formals
          if (identical(rhs[[1]], as.name("function"))) {
            return(formals(eval(rhs)))
          }
        }
      }
    }

    NULL
  }, error = function(e) {
    # Fallback: regex-based extraction
    extract_params_regex(file_path, function_name)
  })
}

# Regex fallback for unparseable files
extract_params_regex <- function(file_path, function_name) {
  lines <- readLines(file_path)

  # Find function definition line
  fn_line <- grep(paste0("^", function_name, "\\s*<-\\s*function\\s*\\("), lines)
  if (length(fn_line) == 0) return(NULL)

  # Extract signature (may span multiple lines)
  sig_text <- lines[fn_line]

  # Simple extraction: split by comma, remove defaults
  params <- strsplit(sig_text, "\\(|\\)")[[1]][2]
  params <- strsplit(params, ",")[[1]]
  params <- trimws(gsub("=.*", "", params))

  params[params != ""]
}
```

### Building Test Value Mapping

```r
# Source: Test generator logic (to be implemented)

#' Get appropriate test value for a parameter name
#' @param param_name Parameter name from function signature
#' @param param_examples Optional examples from roxygen
#' @return Test value of appropriate type
get_test_value_for_param <- function(param_name, param_examples = NULL) {
  # Priority 1: Use roxygen examples if available
  if (!is.null(param_examples) && length(param_examples) > 0) {
    return(param_examples[1])
  }

  # Priority 2: Mapping table
  mapping <- list(
    # Identifiers
    query = "DTXSID7020182",
    dtxsid = "DTXSID7020182",
    dtxcid = "DTXCID7020182",
    casrn = "80-05-7",
    smiles = "c1ccccc1",

    # Numeric
    limit = 100L,
    offset = 0L,
    top = 10L,
    skip = 0L,
    page = 1L,

    # String
    search_type = "equals",
    list_name = "PRODWATER",

    # Boolean
    tidy = TRUE,
    verbose = FALSE
  )

  # Exact match
  if (param_name %in% names(mapping)) {
    return(mapping[[param_name]])
  }

  # Pattern matching
  if (grepl("limit|count|size|top", param_name, ignore.case = TRUE)) {
    return(100L)
  }
  if (grepl("offset|skip|start|page", param_name, ignore.case = TRUE)) {
    return(0L)
  }
  if (grepl("tidy|verbose", param_name, ignore.case = TRUE)) {
    return(TRUE)
  }

  # Default
  "DTXSID7020182"
}

#' Generate batch test values
#' @param param_name Parameter name
#' @return Vector of 2-3 test values
get_batch_test_values <- function(param_name) {
  single_val <- get_test_value_for_param(param_name)

  # For DTXSIDs, use canonical set
  if (is.character(single_val) && grepl("DTXSID", single_val)) {
    return(c("DTXSID7020182", "DTXSID3060245", "DTXSID4048141"))
  }

  # For SMILES
  if (param_name == "smiles") {
    return(c("c1ccccc1", "CC(C)O"))
  }

  # For numeric, return small range
  if (is.integer(single_val)) {
    return(c(single_val, single_val + 10L))
  }

  # Default: duplicate single value
  rep(single_val, 2)
}
```

### Test Generation Template

```r
# Source: Test generator (to be implemented)

#' Generate test file for a function
#' @param function_name Name of function (e.g., "chemi_arn_cats")
#' @param function_file Path to R source file
#' @param output_dir Path to tests/testthat directory
generate_test_file <- function(function_name, function_file, output_dir) {
  # Extract function metadata
  params <- extract_function_params(function_file, function_name)
  tidy_flag <- extract_tidy_flag(function_file)

  # Determine assertion type
  return_assertion <- if (tidy_flag) {
    'expect_s3_class(result, "tbl_df")'
  } else {
    'expect_type(result, "list")'
  }

  # Get test values
  if (length(params) == 0) {
    # Static endpoint (no parameters)
    single_call <- paste0(function_name, "()")
    batch_call <- NULL
  } else {
    primary_param <- names(params)[1]
    single_val <- get_test_value_for_param(primary_param)
    batch_vals <- get_batch_test_values(primary_param)

    single_call <- glue::glue('{function_name}({primary_param} = "{single_val}")')
    batch_call <- glue::glue('{function_name}({primary_param} = c({paste0("\\"", batch_vals, "\\"", collapse = ", ")}))')
  }

  # Generate test file content
  test_content <- glue::glue('
# Tests for {function_name}
# Generated using metadata-based test generator

test_that("{function_name} works with single input", {{
  vcr::use_cassette("{function_name}_single", {{
    result <- {single_call}
    {return_assertion}
  }})
}})

test_that("{function_name} handles batch requests", {{
  vcr::use_cassette("{function_name}_batch", {{
    result <- {batch_call}
    {return_assertion}
  }})
}})

test_that("{function_name} handles errors gracefully", {{
  expect_error({function_name}())
}})
  ')

  # Write to file
  test_file <- file.path(output_dir, paste0("test-", function_name, ".R"))
  writeLines(test_content, test_file)

  cli::cli_alert_success("Generated {test_file}")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual test writing | Auto-generated tests from metadata | v2.1 (this phase) | Scales to 300+ functions |
| Blind parameter guessing | Type-aware parameter mapping | v2.1 (this phase) | Fixes 834+ test failures |
| Separate schema selection logic | Unified schema selection (Item 2) | v2.1 (this phase) | Eliminates diff/stub mismatch |
| No drift detection | Parameter drift reporting (Item 3) | v2.1 (this phase) | Catches API changes early |
| httptest2 | vcr | Already established | Simpler cassette management |
| httr | httr2 | Already established | Modern async support |

**Deprecated/outdated:**
- Manual .Rd files: Use roxygen2 `@param` tags instead
- `use_mit_license()` as license string: It's a function call, not a license spec
- Unfiltered VCR cassettes: Always use `filter_sensitive_data` for API keys

## Open Questions

1. **httr2 version compatibility (BUILD-05)**
   - What we know: Current code uses `httr2::resp_is_transient` and `httr2::resp_status_class` which don't exist in installed httr2 version
   - What's unclear: Which httr2 version introduced these functions? Should we bump minimum version or replace with custom helpers?
   - Recommendation: Check httr2 changelog, then either update DESCRIPTION to require newer httr2 OR replace with custom `is_transient_error()` helper (already exists in codebase at R/z_generic_request.R:99)

2. **Manual stub edits vs pure generated code**
   - What we know: Some stubs may have manual post-generation edits
   - What's unclear: How to detect which files are pure-generated vs manually edited before regenerating
   - Recommendation: Check git history for files in R/ modified outside of automated commits, or add generation timestamp comment to detect stale stubs

3. **Drift detection parse vs regex approach**
   - What we know: Parse-based is robust but fails on syntax errors; regex-based works on unparseable files but is fragile
   - What's unclear: Which approach handles edge cases better in practice
   - Recommendation: Implement parse-based as primary with regex fallback (pattern shown in code examples)

## Validation Architecture

> Test infrastructure is the FOCUS of this milestone, so this section is critical.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.0.0+ |
| Config file | `tests/testthat.R` (existing) |
| Quick run command | `devtools::test()` |
| Full suite command | `devtools::check()` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BUILD-01 | Stub generator produces valid R syntax | unit | `testthat::test_file("tests/testthat/test-stub-generator.R")` | ❌ Wave 0 |
| BUILD-02 | Imports declared correctly | manual | R CMD check | ✅ (DESCRIPTION) |
| BUILD-03 | No non-ASCII characters | manual | R CMD check | ✅ (will fix) |
| BUILD-04 | No import collisions | manual | R CMD check | ✅ (will fix) |
| BUILD-05 | httr2 functions exist | unit | `testthat::test_file("tests/testthat/test-httr2-compat.R")` | ❌ Wave 0 |
| BUILD-06 | Roxygen params match signatures | manual | R CMD check | ✅ (will fix) |
| BUILD-07 | Valid CRAN license | manual | R CMD check | ✅ (will fix) |
| BUILD-08 | No partial argument match | manual | R CMD check | ✅ (will fix) |
| TGEN-01 | Test generator extracts param names correctly | unit | `testthat::test_file("tests/testthat/test-test-generator.R")` | ❌ Wave 0 |
| TGEN-02 | Test generator reads tidy flag correctly | unit | `testthat::test_file("tests/testthat/test-test-generator.R")` | ❌ Wave 0 |
| TGEN-03 | Test generator handles no-param functions | unit | `testthat::test_file("tests/testthat/test-test-generator.R")` | ❌ Wave 0 |
| TGEN-04 | Test generator handles path_params | unit | `testthat::test_file("tests/testthat/test-test-generator.R")` | ❌ Wave 0 |
| TGEN-05 | Generated tests use unique cassette names | unit | `testthat::test_file("tests/testthat/test-test-generator.R")` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `devtools::test()` — run affected tests only
- **Per wave merge:** `devtools::check()` — full R CMD check with all tests
- **Phase gate:** R CMD check must produce 0 errors, 0 warnings before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/testthat/test-stub-generator.R` — unit tests for `build_function_stub()` covering BUILD-01
- [ ] `tests/testthat/test-test-generator.R` — unit tests for test generator covering TGEN-01 through TGEN-05
- [ ] `tests/testthat/test-httr2-compat.R` — verify httr2 helper functions exist (BUILD-05)
- [ ] `tests/testthat/test-drift-detection.R` — unit tests for `detect_parameter_drift()` (Item 3)

## Sources

### Primary (HIGH confidence)

- [vcr package vignette](https://docs.ropensci.org/vcr/articles/vcr.html) - VCR testing best practices
- [HTTP testing in R book](https://books.ropensci.org/http-testing/vcr.html) - VCR configuration and security
- [R packages book: Licensing](https://r-pkgs.org/license.html) - CRAN license specification requirements
- [usethis licenses reference](https://usethis.r-lib.org/reference/licenses.html) - License setup functions
- [R packages book: Function documentation](https://r-pkgs.org/man.html) - Roxygen2 documentation patterns
- [rlang::fn_fmls()](https://rlang.r-lib.org/reference/fn_fmls.html) - Function formals extraction
- [R-hub blog: Code generation in R packages](https://blog.r-hub.io/2020/02/10/code-generation/) - Code generation patterns

### Secondary (MEDIUM confidence)

- [GitHub: non-ASCII character fixes](https://github.com/ThinkR-open/golem/discussions/659) - Unicode escape patterns
- [R tools showNonASCII](https://rdrr.io/r/tools/showNonASCII.html) - Non-ASCII detection
- [httr2 package documentation](https://httr2.r-lib.org/) - HTTP client API reference

### Tertiary (LOW confidence)

- Web search results on httr2 body parameters - No definitive answer on partial match issue, needs codebase investigation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all tools are R ecosystem standards
- Architecture: HIGH - patterns verified in existing codebase and official docs
- Pitfalls: HIGH - directly observed in TODO.md and test failures
- Test generator approach: MEDIUM - design is sound but implementation complexity is untested

**Research date:** 2026-02-27
**Valid until:** 2026-03-29 (30 days - stable R ecosystem)

---

*Research complete. Ready for planning.*
