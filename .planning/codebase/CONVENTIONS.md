# Coding Conventions

**Analysis Date:** 2026-02-12

## Naming Patterns

**Files:**
- Function wrapper files use standardized prefixes: `ct_*.R`, `chemi_*.R`, `util_*.R`
- Example files: `ct_hazard.R`, `chemi_toxprint.R`, `util_cas.R`
- Helper/infrastructure files use `z_` prefix for alphabetical ordering: `z_generic_request.R`
- Internal initialization files use `zzz.R` (follows R package convention)
- Utilities use single lowercase words or `_` separation: `clean_unicode.R`, `extract_mixture.R`

**Functions:**
- camelCase for all exported and internal functions
- Prefix-based organization:
  - `ct_*`: CompTox Dashboard API wrappers (e.g., `ct_hazard()`, `ct_cancer()`)
  - `chemi_*`: Cheminformatics API wrappers (e.g., `chemi_toxprint()`, `chemi_classyfire()`)
  - `util_*`: Utility functions (e.g., `util_cas()`, `util_classyfire()`)
  - `*_server()`: Configuration functions (e.g., `ctx_server()`, `chemi_server()`)
  - `is_*`: Boolean checking functions (e.g., `is_cas()`)
  - `extract_*`: Extraction/parsing functions (e.g., `extract_mixture()`, `extract_mol_formula()`)

**Variables:**
- snake_case for local and internal variables
- camelCase acceptable in parameter names (e.g., `batch_limit`, `api_key`)
- All uppercase for environment variable names and constants
- Query parameters use underscores: `query`, `batch_limit`, `body_type`

**Types & Parameters:**
- `query`: Primary input parameter for API functions (flexible - can be DTXSID, CAS, SMILES, etc.)
- `endpoint`: API endpoint path string
- `method`: HTTP method ("POST" or "GET")
- `server`: Environment variable name or direct URL string
- `batch_limit`: Items per request (0=static, 1=path-based GET, >1=bulk POST)
- `auth`: Boolean flag for API key inclusion
- `tidy`: Boolean flag for tibble vs. list return
- `options`: Named list of cheminformatics-specific parameters

## Code Style

**Formatting:**
- Line length: No enforced limit (`.lintr.R` disables line_length_linter)
- Indentation: 2 spaces (R convention)
- Spacing: Follows standard R conventions

**Linting:**
- Tool: lintr via `.lintr.R`
- Disabled rules:
  - `line_length_linter`: No line length limit
  - `commented_code_linter`: Allows commented code blocks
  - `whitespace_linter`: Flexible whitespace rules
- Encoding: UTF-8

**Pipe operators:**
- Magrittr pipe `%>%` used in data manipulation functions
- Modern `|>` native pipe supported but not enforced
- Pipelines typically short (1-5 steps in most functions)

## Import Organization

**Order:**
1. Standard library imports (e.g., `library(cli)`, `library(dplyr)`)
2. Package-specific imports via roxygen `@importFrom`
3. Explicit namespace calls for cross-package functions

**Path Aliases:**
- Not explicitly used; instead uses environment variables for API endpoints
- Environment variables stored in package namespace:
  - `ctx_burl`: CompTox Dashboard URL
  - `chemi_burl`: Cheminformatics URL
  - `epi_burl`: EPI Suite URL
  - `eco_burl`: ECOTOX URL
  - `batch_limit`: Default batch size (100-1000)
  - `run_debug`: Debug mode flag
  - `run_verbose`: Verbose output flag

**Roxygen Documentation:**
- All exported functions have roxygen comments
- Standard tags: `@param`, `@return`, `@export`, `@examples`, `@importFrom`
- Examples wrapped in `\dontrun{}` for API-dependent functions
- `@examples` typically show single DTXSID usage

## Error Handling

**Patterns:**
- Use `cli` package for all user-facing errors and warnings
- `cli::cli_abort()`: Abort execution with formatted error message
- `cli::cli_warn()`: Issue formatted warning
- `stopifnot()`: Assert preconditions for input validation
- Error messages use glue interpolation: `{.val {var_name}}`

**Key error types in `generic_request()`:**
- Empty query validation: `cli::cli_abort("Query must be a character vector.")`
- Invalid path parameter usage: `cli::cli_abort("Cannot use path_params with batching...")`
- API status errors: `cli::cli_warn("API request to {.val {endpoint}} failed...")`
- No results: `cli::cli_warn("No results found for the given query in {.val {endpoint}}.")`

**HTTP error handling:**
- 4xx/5xx responses: Issue warning, return NULL for that batch
- Empty results: Issue warning, return empty tibble or list
- Network timeouts: Caught in tryCatch, converted to user-friendly message

## Logging

**Framework:** cli package (not base R `message()`)

**Patterns:**
- Verbose mode enabled via `Sys.getenv("run_verbose")`
- Debug mode enabled via `Sys.getenv("run_debug")`
- When verbose=TRUE:
  - `cli::cli_rule()`: Section headers with endpoint name
  - `cli::cli_dl()`: Named list of debug information (item count, batch count, method)
  - Example from `generic_request()`:
    ```r
    if (run_verbose) {
      cli::cli_rule(left = paste('Generic Request:', endpoint))
      cli::cli_dl(c(
        'Number of items' = '{length(query)}',
        'Number of batches' = '{mult_count}',
        'Method' = '{method}'
      ))
    }
    ```
- Debug mode (run_debug=TRUE): Prints request construction without executing HTTP calls

**Startup logging:**
- `run_setup()` function provides endpoint connectivity check and latency reporting
- Color-coded status: green (OK), yellow (WARN), red (ERROR)
- Latency displayed in milliseconds

## Comments

**When to Comment:**
- Explain WHY, not WHAT (code should be self-explanatory)
- Complex regex patterns: Include explanation of groups and intent
- Algorithm steps: Number each major step (e.g., "--- 1. Base URL Resolution ---")
- TODO comments mark incomplete refactoring: `# TODO Migrate to generic requests + promote to stable after testing`

**JSDoc/TSDoc:**
- R uses roxygen comments (`#'`) for function documentation
- Standard tags:
  - `@title`: One-line description
  - `@description`: Detailed explanation (if needed)
  - `@param`: Parameter documentation with type and description
  - `@return`: Return value type and description
  - `@examples`: Runnable examples (or `\dontrun{}` for API calls)
  - `@export`: Mark function as exported
  - `@importFrom`: Declare cross-package function usage

**Example from `ct_hazard()`:**
```r
#' Retrieves hazard data by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard(query = "DTXSID7020182")
#' }
```

## Function Design

**Size:**
- Most wrapper functions: 5-25 lines (simple parameter forwarding to templates)
- Template functions (`generic_request`, `generic_chemi_request`): 150-300+ lines (handles complexity)
- Utility functions: 20-60 lines
- No enforced limit; lintr does not check function length

**Parameters:**
- Explicit over implicit (rarely use `...` except in template functions)
- Defaults provided for optional parameters
- Query/input parameter always first
- Configuration parameters (batch_limit, auth, etc.) follow method/endpoint parameters

**Return Values:**
- API wrapper functions return tibbles by default (`tidy=TRUE`)
- Can return raw list with `tidy=FALSE` for custom post-processing
- Graceful handling of empty results: empty tibble or list (never NULL unless error)
- Consistent structure across similar functions

**Example wrapper pattern:**
```r
ct_hazard <- function(query) {
  generic_request(
    query = query,
    endpoint = "hazard/toxval/search/by-dtxsid/",
    method = "POST"
  )
}
```

## Module Design

**Exports:**
- Single function per file (typical pattern): `ct_hazard()` in `ct_hazard.R`
- Multiple related functions allowed: `chemi_safety_sections()` and helpers in `chemi_safety_sections.R`
- All user-facing functions marked with `@export`
- Internal utility functions not exported

**Barrel Files:**
- Not used; each function has its own file
- Makes it easier to trace dependencies and find implementation

**Package initialization:**
- `zzz.R` contains `.onAttach()` and `.onLoad()` hooks
- `.onLoad()` initializes `.ComptoxREnv` for session-level caching
- `.onAttach()` configures server URLs based on package version and displays setup info

## Session-Level Caching

**Pattern:**
- Internal environment: `.ComptoxREnv <- new.env(parent = emptyenv())`
- Pre-compiled regex and classifiers stored to avoid repeated initialization
- Example: `.ComptoxREnv$extractor`, `.ComptoxREnv$classifier`

**Usage:**
- Accessed directly by functions: `.ComptoxREnv$object_name`
- Initialized once per session in `.onLoad()`

## API Request Templates

**Generic Request Template (`generic_request()` in `R/z_generic_request.R`):**
- Primary template used by ~70% of API wrapper functions
- Handles: query normalization, batching, authentication, error handling, tibble conversion
- Key parameters:
  - `batch_limit`: 0=static, 1=path-based GET, >1=bulk POST
  - `method`: "POST" or "GET"
  - `tidy`: TRUE for tibble, FALSE for list
  - `path_params`: Additional URL path segments (cannot be used with batching)
  - `body_type`: "json" or "raw_text" (for special endpoints)
  - `content_type`: Response type ("application/json", "text/plain", "image/*")

**Cheminformatics Template (`generic_chemi_request()` in `R/z_generic_request.R`):**
- Specialized template for cheminformatics microservices
- Handles nested payload structure: `{"chemicals": [...], "options": {...}}`
- Key parameters:
  - `options`: Named list of chemi-specific parameters
  - `sid_label`: Identifier key in payload (default: "sid")
  - `wrap`: TRUE to nest in chemicals/options, FALSE for direct array
  - `pluck_res`: Extract specific field from response

---

*Convention analysis: 2026-02-12*
