# Phase 28: Thin Wrapper Migration - Research

**Researched:** 2026-03-10
**Domain:** R package hook systems, YAML-based configuration, stub generation, test automation
**Confidence:** HIGH

## Summary

Phase 28 migrates 14 hand-written ct_* wrapper functions to generated stubs by building a deterministic hook injection system. The system has three components: (1) YAML-based hook registry populated at .onLoad, (2) reusable hook primitives in R/hooks/, and (3) generator extensions to inject hook-declared parameters into function signatures.

The research confirms this approach is proven and low-risk: R's environment-based registry pattern is standard (used for extractors/classifiers in zzz.R), YAML config loading via yaml::read_yaml is mature, and the pagination parameter injection pattern (lines 357-401 of build_function_stub) provides exact mechanical precedent for hook parameter injection.

**Primary recommendation:** Build hook system incrementally — registry first (validate YAML loading), then primitives (unit test in isolation), then generator integration (extend pagination pattern), then migrate functions one family at a time (pure pass-throughs → pre-hooks → post-hooks → transforms).

## User Constraints

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Hook System Architecture:**
- Registry: `.HookRegistry` environment populated at `.onLoad` from `inst/hook_config.yml`
- Hook files: `R/hooks/` directory, grouped by function family
- Config format: YAML in `inst/hook_config.yml` with YAML list syntax for chains
- Hook types: pre_request, post_response, and transform (replaces default parse pipeline)
- Chain order: pre_request → (generic_request) → transform OR default parse → post_response
- No-op handling: Runtime — `run_hook('fn_name', 'type', data)` returns input unchanged if nothing registered
- Composability: Shared reusable primitives (validate_dtxsid, flatten_nested, etc.) composed per-function via YAML lists

**Hook Parameter Injection:**
- Mechanism: YAML `extra_params` section in `inst/hook_config.yml` declares parameters per function
- Generator reads config: Extends existing pagination pattern (append to fn_signature, add @param docs)
- CI enforcement: Config-drift check blocks build if YAML extra_params don't match generated formals
- Rationale: Only option where failure mode (config drift) is detectable by CI; produces explicit typed params with IDE autocomplete

**Function Migration Strategy:**
- Pure pass-throughs (8 functions): Delete immediately — ct_hazard, ct_cancer, ct_env_fate, ct_demographic_exposure, ct_general_exposure, ct_functional_use, ct_functional_use_probability, ct_genotox
- Pre-hook needed (2): ct_similar (validation), ct_list (str_to_upper)
- Post-hook needed (1): ct_compound_in_list (extract/format/cli messages)
- Transform needed (1): ct_lists_all (conditional projection + coerce/split)
- Break apart + hooks (2): ct_bioactivity → 4 stubs, ct_properties → 2 stubs
- Naming: No aliases — generated stub names become public API (clean break)

**Deprecated/Dead Code:**
- ct_descriptors: Delete entirely (deprecated INDIGO endpoint, raw httr2)
- ct_synonym: Delete after confirming generated stub exists
- ct_related: Leave untouched (ad-hoc web scraper, not standard API wrapper)

**Testing Strategy:**
- Hook tests: Unit tests with mock data (hand-crafted tibbles/lists), test primitives in isolation, no VCR
- Test generator: Updated to read hook_config.yml and auto-generate test variants
- CI drift check: Blocks build (error, not warning) if YAML extra_params don't match generated formals

### Claude's Discretion

- Exact hook registry implementation (environment structure, lookup optimization)
- Hook primitive function signatures and internal composition mechanics
- Generator code structure for reading YAML config and injecting extra_params
- Which reusable primitives to extract vs. function-specific hooks
- How to structure the CI config-drift check script

### Deferred Ideas (OUT OF SCOPE)

- Auditing all 400+ stubs for potential hook opportunities — Phase 29/30 concern
- ct_related migration — may never fit stub model
- `hooks = list()` namespace pattern (Gadfly alternative) — revisit if hook param count exceeds ~30 functions
- Post-processing recipe system (#120) — deferred per earlier project decision
</user_constraints>

## Standard Stack

### Core: Hook System Libraries

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| yaml | Latest CRAN | YAML parsing | De facto standard for config files in R ecosystem, 10+ years mature |
| testthat | 3.2+ | Hook unit testing | Project standard, supports local_mocked_bindings for hook isolation |
| glue | Latest | String templating | Already used in generator (build_function_stub), proven for code generation |
| cli | Latest | Hook error messages | Project standard for user-facing messages |

### Supporting: Generator Extensions

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| purrr | Latest | Hook composition | Already imported selectively (map, pluck, etc.) |
| stringr | Latest | Param name manipulation | Already in use throughout generator |
| jsonlite | Latest | Test manifest updates | Already imported for dev/generate_tests.R |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| yaml | JSON config | YAML more readable for multi-line hook chains; JSON nested lists harder to edit |
| Environment registry | R6 class | Environment simpler, no dependency; R6 adds OOP overhead for simple key-value storage |
| .onLoad hook loading | Runtime lazy loading | .onLoad guarantees hooks available at package attach; lazy loading risks race conditions |

**Installation:**

No new dependencies — all libraries already in ComptoxR DESCRIPTION (Imports or Suggests).

## Architecture Patterns

### Recommended Project Structure

```
inst/
└── hook_config.yml                # Hook registry config
R/
├── hooks/
│   ├── bioactivity_hooks.R        # ct_bioactivity annotate post-hook
│   ├── list_hooks.R               # ct_list str_to_upper, ct_lists_all transform
│   ├── compound_hooks.R           # ct_compound_in_list extract/format
│   ├── validation_hooks.R         # ct_similar validation pre-hook
│   └── utils_hooks.R              # Shared primitives (validate_dtxsid, flatten_nested)
├── hook_registry.R                # Registry management (load_hooks, run_hook)
└── zzz.R                          # .onLoad extended to populate .HookRegistry
dev/
├── check_hook_config.R            # CI drift detection script
└── endpoint_eval/
    └── 07_stub_generation.R       # Extended to inject hook params
tests/testthat/
├── test-hook_primitives.R         # Unit tests for hook functions
└── test-hook_registry.R           # Unit tests for registry lookup
```

### Pattern 1: Hook Registry at .onLoad

**What:** Populate `.HookRegistry` environment from `inst/hook_config.yml` when package loads

**When to use:** Every time package is attached (library(ComptoxR))

**Example:**

```r
# R/zzz.R (extend existing .onLoad)
.HookRegistry <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # Existing initialization
  .ComptoxREnv$extractor <- create_formula_extractor_final()
  .ComptoxREnv$classifier <- create_compound_classifier()

  # NEW: Load hook configuration
  config_path <- system.file("hook_config.yml", package = "ComptoxR")
  if (file.exists(config_path)) {
    hook_config <- yaml::read_yaml(config_path)
    .HookRegistry$config <- hook_config
  }
}
```

**Source:** Pattern mirrors existing `.ComptoxREnv` usage (lines 594-602 of R/zzz.R).

### Pattern 2: Hook Primitive Functions

**What:** Small, testable functions that perform single transformations

**When to use:** Compose primitives into hook chains via YAML config

**Example:**

```r
# R/hooks/validation_hooks.R
#' Validate similarity threshold
#' @param data List with similarity parameter
#' @return data unchanged or aborts if invalid
#' @noRd
validate_similarity <- function(data) {
  similarity <- data$params$similarity
  if (!is.null(similarity)) {
    if (!is.numeric(similarity)) {
      cli::cli_abort("Similarity threshold must be numeric")
    }
    if (similarity < 0 || similarity > 1) {
      cli::cli_abort("Similarity threshold must be between 0 and 1")
    }
  }
  data
}

# R/hooks/list_hooks.R
#' Uppercase list names
#' @param data List with query field
#' @return data with query uppercased
#' @noRd
uppercase_query <- function(data) {
  data$params$query <- stringr::str_to_upper(data$params$query)
  data
}
```

**Source:** Inspired by testthat's mock function pattern and Vue composables testing (isolated, single-responsibility functions).

### Pattern 3: YAML Hook Configuration

**What:** Declarative hook chains for each function

**When to use:** Register which hooks run for which generated stub

**Example:**

```yaml
# inst/hook_config.yml
ct_list:
  extra_params:
    extract_dtxsids:
      default: "TRUE"
      type: "logical"
      description: "Extract DTXSIDs from results"
  pre_request:
    - uppercase_query
  post_response:
    - extract_dtxsids_if_requested

ct_similar:
  extra_params:
    similarity:
      default: "0.8"
      type: "numeric"
      description: "Similarity threshold (0-1)"
  pre_request:
    - validate_similarity

ct_bioactivity_data_search_bulk:
  extra_params:
    annotate:
      default: "FALSE"
      type: "logical"
      description: "Join assay annotations"
  post_response:
    - annotate_assay_if_requested
```

**Source:** YAML config pattern from {config} package, list syntax standard YAML.

### Pattern 4: Generator Parameter Injection

**What:** Extend pagination pattern to inject hook-declared parameters

**When to use:** During stub generation (dev/endpoint_eval/07_stub_generation.R)

**Example:**

```r
# dev/endpoint_eval/07_stub_generation.R (NEW section after pagination)
# =========================================================================
# Hook Parameter Injection (Phase 28)
# =========================================================================
hook_config_path <- here::here("inst", "hook_config.yml")
hook_params <- ""

if (file.exists(hook_config_path)) {
  hook_config <- yaml::read_yaml(hook_config_path)
  fn_config <- hook_config[[fn]]

  if (!is.null(fn_config$extra_params)) {
    # Append each param to fn_signature
    for (param_name in names(fn_config$extra_params)) {
      param_spec <- fn_config$extra_params[[param_name]]
      default_val <- param_spec$default

      fn_signature <- paste0(fn_signature, ", ", param_name, " = ", default_val)

      # Add @param doc
      param_docs <- paste0(
        param_docs,
        "#' @param ", param_name, " ", param_spec$description, "\n"
      )
    }
  }
}
```

**Source:** Direct extension of pagination injection pattern (lines 357-401), proven by existing `all_pages` parameter.

### Pattern 5: Runtime Hook Execution

**What:** Call registered hooks at appropriate stub lifecycle points

**When to use:** Generated stubs call run_hook() before/after generic_request

**Example:**

```r
# R/hook_registry.R
#' Run registered hook(s) for a function
#' @param fn_name Function name (e.g., "ct_list")
#' @param hook_type One of "pre_request", "post_response", "transform"
#' @param data Input data (params for pre_request, response for post_response)
#' @return Transformed data or original if no hooks registered
#' @noRd
run_hook <- function(fn_name, hook_type, data) {
  config <- .HookRegistry$config
  if (is.null(config) || is.null(config[[fn_name]])) {
    return(data)
  }

  hook_chain <- config[[fn_name]][[hook_type]]
  if (is.null(hook_chain)) {
    return(data)
  }

  # Execute hook chain
  for (hook_name in hook_chain) {
    hook_fn <- get(hook_name, mode = "function", envir = parent.frame())
    data <- hook_fn(data)
  }

  data
}

# Generated stub example
ct_list_search_by_name <- function(listName, extract_dtxsids = TRUE) {
  # Pre-request hook
  req_data <- run_hook("ct_list", "pre_request", list(params = list(query = listName)))

  # Request
  result <- generic_request(
    query = req_data$params$query,
    endpoint = "chemical/list/search/by-name/",
    method = "GET",
    batch_limit = 1,
    tidy = FALSE
  )

  # Post-response hook
  result <- run_hook("ct_list", "post_response", list(
    result = result,
    params = list(extract_dtxsids = extract_dtxsids)
  ))

  result
}
```

**Source:** Hook execution pattern inspired by R's setHook/getHook system and Vue composables lifecycle pattern.

### Anti-Patterns to Avoid

- **Hardcoded hook function names in stubs:** Use YAML config lookup to keep stubs deterministic and hooks swappable
- **Hooks mutating global state:** Hooks must be pure functions (input → output) for testability
- **Skipping CI drift check:** Config-param mismatch is silent failure — always enforce in CI
- **Complex hook chains without primitives:** Break down complex logic into small testable primitives, compose via YAML
- **Mixing hook types:** Don't put validation (pre_request) logic in post_response hooks — respect lifecycle boundaries

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML parsing | Custom parser | yaml::read_yaml | 10+ years mature, handles edge cases (multi-line, escaping, nested lists) |
| Config validation | Manual schema checks | Check at .onLoad + CI drift script | Runtime validation catches user errors, CI catches developer config drift |
| Hook function discovery | Scan R/ directory | Explicit registration via YAML | Deterministic, no magic filesystem scanning, easier to debug |
| Parameter type conversion | String parsing | Store type metadata in YAML | Generator can inject proper R types (logical vs "TRUE" string) |
| Test data fixtures | VCR cassettes for hooks | Hand-crafted tibbles/lists | Hooks operate on R objects, not HTTP; mock data faster and clearer |

**Key insight:** Hook systems are fundamentally about function composition and dispatch — leverage R's environment semantics and existing proven patterns (pagination injection, .onLoad initialization) rather than inventing new mechanisms.

## Common Pitfalls

### Pitfall 1: Config-Param Drift Goes Undetected

**What goes wrong:** YAML declares `similarity` parameter but generator doesn't inject it → function signature mismatch → user gets "unknown parameter" error

**Why it happens:** Config and generator are separate steps; no automated check ensures consistency

**How to avoid:** CI script compares generated function formals against YAML extra_params and fails build on mismatch

**Warning signs:** Test failures with "argument 'X' not matched" errors after stub regeneration

### Pitfall 2: Hook Function Not Found at Runtime

**What goes wrong:** YAML references hook function name that doesn't exist or isn't exported → run_hook() fails with "object not found"

**Why it happens:** YAML is just text; no compile-time validation that referenced functions exist

**How to avoid:** CI script sources all R/hooks/*.R files and validates YAML-referenced hooks are defined

**Warning signs:** Package load failure or runtime errors only when hook is triggered

### Pitfall 3: Transform Hooks Return Wrong Type

**What goes wrong:** Transform hook returns list but generated stub expects tibble (or vice versa) → downstream code breaks

**Why it happens:** Transform hook replaces default parsing; must match expected return type

**How to avoid:** Hook tests assert return type; generator enforces tidy flag consistency with transform presence

**Warning signs:** "$ operator is invalid for atomic vectors" or "object of type 'list' is not subsettable"

### Pitfall 4: Hook Params Not Passed Through

**What goes wrong:** Hook needs to access extra_param value but it's not in hook data structure → hook can't implement conditional logic

**Why it happens:** Generated stub doesn't pass params to run_hook()

**How to avoid:** Standardize hook data structure: `list(params = <user args>, result = <response>)` for all hook types

**Warning signs:** Hook functions accessing params via parent.frame() or global state (fragile)

### Pitfall 5: Breaking Existing Users During Migration

**What goes wrong:** Users call `ct_hazard()` after migration but function is deleted → code breaks

**Why it happens:** Migration removes friendly-name wrappers, forcing users to new generated names

**How to avoid:** Migration decision is locked — no deprecation shim, clean break. Document breaking change in NEWS.md and migration guide.

**Warning signs:** N/A — this is intentional breaking change per user decision

## Code Examples

Verified patterns from existing codebase and standard R practices:

### Environment Registry Pattern (Existing)

```r
# R/zzz.R (lines 594-602) — EXISTING PATTERN TO EXTEND
.ComptoxREnv <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .ComptoxREnv$extractor <- create_formula_extractor_final()
  .ComptoxREnv$classifier <- create_compound_classifier()
}
```

**Extension for hooks:**

```r
# R/zzz.R (EXTEND existing .onLoad)
.HookRegistry <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # Existing
  .ComptoxREnv$extractor <- create_formula_extractor_final()
  .ComptoxREnv$classifier <- create_compound_classifier()

  # NEW: Hook registry
  config_path <- system.file("hook_config.yml", package = "ComptoxR")
  if (file.exists(config_path)) {
    .HookRegistry$config <- yaml::read_yaml(config_path)
  } else {
    .HookRegistry$config <- list()
  }
}
```

### Pagination Parameter Injection (Existing)

```r
# dev/endpoint_eval/07_stub_generation.R (lines 357-401) — EXISTING PATTERN TO REPLICATE
if (!isTRUE(pagination_strategy == "none") && !is.null(pagination_strategy)) {
  # 1. Set defaults for pagination params in signature
  # ... (gsub replacements for offset, page, etc.)

  # 2. Append all_pages = TRUE to signature
  if (nzchar(fn_signature_check)) {
    fn_signature <- paste0(fn_signature, ", all_pages = TRUE")
  } else {
    fn_signature <- "all_pages = TRUE"
  }

  # 3. Add @param documentation
  param_docs <- paste0(
    param_docs,
    "#' @param all_pages Logical; if TRUE (default), automatically fetches all pages.\n"
  )

  # 4. Build pagination call params
  pagination_call_params <- paste0(
    ",\n    paginate = all_pages",
    ",\n    max_pages = 100",
    ',\n    pagination_strategy = "', pagination_strategy, '"'
  )
}
```

**Hook parameter injection follows same pattern:**

```r
# NEW: After pagination section
hook_config_path <- here::here("inst", "hook_config.yml")
if (file.exists(hook_config_path)) {
  hook_config <- yaml::read_yaml(hook_config_path)
  fn_config <- hook_config[[fn]]

  if (!is.null(fn_config$extra_params)) {
    for (param_name in names(fn_config$extra_params)) {
      param_spec <- fn_config$extra_params[[param_name]]

      # 1. Append to signature
      fn_signature <- paste0(fn_signature, ", ", param_name, " = ", param_spec$default)

      # 2. Add @param doc
      param_docs <- paste0(
        param_docs,
        "#' @param ", param_name, " ", param_spec$description, "\n"
      )
    }
  }
}
```

### Hook Primitive Example

```r
# R/hooks/list_hooks.R
#' Extract DTXSIDs from list results if requested
#' @param data List with result and params
#' @return Modified result (vector or original)
#' @noRd
extract_dtxsids_if_requested <- function(data) {
  if (!isTRUE(data$params$extract_dtxsids)) {
    return(data$result)
  }

  dat <- data$result

  # Handle duplicate names (multiple results)
  if (anyDuplicated(names(dat)) > 0) {
    dtxsid_indices <- which(names(dat) == "dtxsids")
    dtxsids <- dat[dtxsid_indices] %>%
      purrr::map(~ stringr::str_split(.x, pattern = ',')) %>%
      unlist() %>%
      unique()
  } else {
    dtxsids <- dat$dtxsids %>%
      stringr::str_split(pattern = ',') %>%
      unlist() %>%
      unique()
  }

  dtxsids
}
```

**Source:** Extracted from R/ct_list.R (lines 32-48), refactored as hook primitive.

### Unit Test for Hook Primitive

```r
# tests/testthat/test-hook_primitives.R
test_that("extract_dtxsids_if_requested extracts and splits DTXSIDs", {
  # Hand-crafted mock data
  mock_result <- list(
    dtxsids = "DTXSID7020182,DTXSID2021028,DTXSID8024845"
  )

  data <- list(
    result = mock_result,
    params = list(extract_dtxsids = TRUE)
  )

  # Execute hook
  result <- extract_dtxsids_if_requested(data)

  # Assertions
  expect_type(result, "character")
  expect_equal(length(result), 3)
  expect_true("DTXSID7020182" %in% result)
})

test_that("extract_dtxsids_if_requested returns original when FALSE", {
  mock_result <- list(dtxsids = "DTXSID7020182")

  data <- list(
    result = mock_result,
    params = list(extract_dtxsids = FALSE)
  )

  result <- extract_dtxsids_if_requested(data)

  expect_type(result, "list")
  expect_equal(result, mock_result)
})
```

**Source:** Pattern from testthat documentation on testing with hand-crafted fixtures.

### CI Drift Check Script

```r
# dev/check_hook_config.R
library(yaml)
library(cli)

# Read hook config
config_path <- here::here("inst", "hook_config.yml")
if (!file.exists(config_path)) {
  cli::cli_abort("hook_config.yml not found")
}

hook_config <- yaml::read_yaml(config_path)

# Source all hook files to validate functions exist
hook_files <- list.files(here::here("R", "hooks"), pattern = "\\.R$", full.names = TRUE)
for (f in hook_files) {
  source(f)
}

errors <- character(0)

# Validate each function's hooks and params
for (fn_name in names(hook_config)) {
  fn_config <- hook_config[[fn_name]]

  # Check hook functions exist
  for (hook_type in c("pre_request", "post_response", "transform")) {
    hook_chain <- fn_config[[hook_type]]
    if (!is.null(hook_chain)) {
      for (hook_fn in hook_chain) {
        if (!exists(hook_fn, mode = "function")) {
          errors <- c(errors, paste0("Function ", fn_name, " references non-existent hook: ", hook_fn))
        }
      }
    }
  }

  # Check generated stub has matching params (requires stub to exist)
  stub_file <- here::here("R", paste0(fn_name, ".R"))
  if (file.exists(stub_file)) {
    stub_expr <- parse(stub_file)
    # Extract formals and compare to extra_params
    # (Implementation depends on parse tree traversal)
  }
}

if (length(errors) > 0) {
  cli::cli_abort(c(
    "Hook config validation failed:",
    errors
  ))
} else {
  cli::cli_alert_success("Hook config validation passed")
}
```

**Source:** Pattern inspired by GitHub Actions YAML validation tools.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-written thin wrappers | Generated stubs + hooks | Phase 28 (2026-03-10) | Eliminates ~14 maintenance files, enables deterministic regeneration |
| Inline validation/formatting | Composable hook primitives | Phase 28 | Reusable logic (e.g., annotate hook shared by 4 bioactivity stubs) |
| Friendly-name aliases (ct_hazard) | Direct generated names (ct_hazard_toxval_search_bulk) | Phase 28 | Breaking change — users adopt generated API directly |
| Custom httr2 code (ct_properties) | generic_request + path_params | Phase 28 | Standardizes property range queries, removes 50 lines of custom HTTP logic |
| Deprecated INDIGO endpoint | Deleted (ct_descriptors) | Phase 28 | Removes undocumented experimental endpoint |

**Deprecated/outdated:**
- `ct_descriptors`: Deleted entirely — INDIGO endpoint not in published API schemas, lifecycle badge "deprecated" since 3.0.0
- `ct_synonym`: Deleted — empty file, 0 lines of code, generated stub exists
- Friendly-name wrappers: No deprecation shim — clean break, users migrate to generated stub names

## Open Questions

1. **Should .prop_ids() become a utility function or hook primitive?**
   - What we know: Currently internal to ct_prop.R, fetches property name mappings from two endpoints
   - What's unclear: Whether property ID lookup is hook-worthy or separate utility
   - Recommendation: Research during ct_properties migration — if used across multiple stubs, extract as utility; if only ct_properties, keep as internal helper

2. **Should hook functions be exported or remain internal (@noRd)?**
   - What we know: Hooks are called by generated stubs via run_hook(), not directly by users
   - What's unclear: Whether advanced users might want to compose hooks manually
   - Recommendation: Keep @noRd (internal) — hooks are implementation detail, not user API; can export later if demand emerges

3. **How granular should hook primitives be?**
   - What we know: ct_compound_in_list has extract → format → cli alert sequence
   - What's unclear: Break into 3 primitives or keep as single post-hook?
   - Recommendation: Start with single hook per function; extract shared primitives only when 2+ functions reuse logic (annotate hook proves composability)

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat 3.2+ |
| Config file | tests/testthat.R (existing) |
| Quick run command | `devtools::test()` |
| Full suite command | `devtools::check()` (includes test suite + R CMD check) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| N/A | Hook registry loads YAML at .onLoad | unit | `testthat::test_file("tests/testthat/test-hook_registry.R")` | ❌ Wave 0 |
| N/A | run_hook() returns input unchanged when no hooks registered | unit | `testthat::test_file("tests/testthat/test-hook_registry.R")` | ❌ Wave 0 |
| N/A | Hook primitives transform data correctly | unit | `testthat::test_file("tests/testthat/test-hook_primitives.R")` | ❌ Wave 0 |
| N/A | Generator injects hook params from YAML | unit | `testthat::test_file("tests/testthat/test-generator_hooks.R")` | ❌ Wave 0 |
| N/A | CI drift check fails on config-param mismatch | integration | `Rscript dev/check_hook_config.R` | ❌ Wave 0 |
| N/A | Migrated functions produce identical output to originals | integration | VCR tests in `test-ct_*.R` files | ✅ Existing (will reuse cassettes) |

### Sampling Rate

- **Per task commit:** `devtools::test()` (hook tests only, ~10 seconds)
- **Per wave merge:** `devtools::check()` (full R CMD check, ~2 minutes)
- **Phase gate:** Full suite green + CI drift check passes before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/testthat/test-hook_registry.R` — covers .onLoad initialization, run_hook() dispatch
- [ ] `tests/testthat/test-hook_primitives.R` — covers all hook functions in R/hooks/
- [ ] `tests/testthat/test-generator_hooks.R` — covers YAML reading and param injection
- [ ] `R/hook_registry.R` — registry management functions
- [ ] `R/hooks/` directory — hook primitive files
- [ ] `inst/hook_config.yml` — hook configuration
- [ ] `dev/check_hook_config.R` — CI drift detection script

## Sources

### Primary (HIGH confidence)

- **Existing Codebase:**
  - `dev/endpoint_eval/07_stub_generation.R` (lines 357-401) — pagination injection pattern
  - `R/zzz.R` (lines 594-602) — .onLoad environment initialization
  - `R/ct_*.R` files — current thin wrapper implementations
  - `dev/generate_tests.R` — test generator structure
  - `.planning/phases/28-thin-wrapper-migration/28-CONTEXT.md` — user decisions

- **R Documentation:**
  - [R Manual: Hooks for Namespace Events](https://stat.ethz.ch/R-manual/R-devel/library/base/html/ns-hooks.html) — .onLoad/.onAttach semantics
  - [R Manual: Functions to Get and Set Hooks](https://stat.ethz.ch/R-manual/R-devel/library/base/html/userhooks.html) — setHook/getHook patterns

### Secondary (MEDIUM confidence)

- **YAML Configuration:**
  - [config package: Getting Started](https://rstudio.github.io/config/articles/introduction.html) — YAML config patterns in R packages
  - [Posit Community: Config YAML in Packages](https://forum.posit.co/t/where-would-you-put-a-config-yml-file-when-building-a-package/132653) — inst/extdata vs inst/ placement

- **Testing Patterns:**
  - [testthat: Unit Testing for R](https://testthat.r-lib.org/) — Mock functions and hand-crafted fixtures
  - [Mocks: Integrating with testthat](https://cran.r-project.org/web/packages/mockery/vignettes/mocks-and-testthat.html) — local_mocked_bindings pattern
  - [Vue Composables Testing](https://alexop.dev/posts/how-to-test-vue-composables/) — Testing composable primitives with lifecycle hooks (conceptual parallel)

- **CI Validation:**
  - [YAML Schema Validator GitHub Action](https://github.com/nrkno/yaml-schema-validator-github-action) — YAML validation in CI
  - [env-check: Environment File Validator](https://github.com/BinaryBard27/env-check) — Config drift detection patterns

### Tertiary (LOW confidence)

- None — all recommendations based on verified codebase patterns or mature R ecosystem practices

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in use, no new dependencies
- Architecture: HIGH — extends proven patterns (pagination injection, .onLoad init), direct codebase precedent
- Hook primitives: HIGH — extracted from existing working code (ct_list, ct_bioactivity, ct_lists_all)
- CI drift detection: MEDIUM — pattern proven in other ecosystems (YAML validation), needs R-specific implementation
- Migration strategy: HIGH — locked user decisions with clear function categorization

**Research date:** 2026-03-10
**Valid until:** 30 days (2026-04-09) — stable ecosystem, no fast-moving dependencies
