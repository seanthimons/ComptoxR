# Phase 10: Pipeline Consolidation - Research

**Researched:** 2026-01-29
**Domain:** R script refactoring and code consolidation
**Confidence:** HIGH

## Summary

This phase refactors `generate_stubs.R` to eliminate divergent code paths across three schema types (ct, chemi, cc). Research focused on understanding the current architecture, identifying duplication patterns, and determining the standard approach for consolidating R pipeline code.

**Current state:** Three generator functions with divergent patterns:
- `generate_ct_stubs()` and `generate_cc_stubs()` both use direct `openapi_to_spec(openapi)` on parsed JSON
- `generate_chemi_stubs()` delegates to `parse_chemi_schemas()` which handles file selection AND parsing
- Only chemi applies filtering (`ENDPOINT_PATTERNS_TO_EXCLUDE`) post-parsing; ct/cc rely on `openapi_to_spec()`'s `preprocess=TRUE` default

**Key finding:** The codebase already has all necessary building blocks. The refactoring is a code organization task, not a feature addition. `openapi_to_spec()` accepts both file paths (with preprocessing) and parsed JSON objects, making it the natural unification point.

**Primary recommendation:** Extract file-selection logic from `parse_chemi_schemas()` into a shared helper, then make all three generators follow the same pattern: select files → load JSON → preprocess (optional) → `openapi_to_spec()` → post-process spec → render stubs.

## Standard Stack

This is a refactoring phase using existing codebase tools. No external libraries required.

### Core (Existing Codebase Tools)
| Library/Function | Purpose | Why Standard |
|------------------|---------|--------------|
| `openapi_to_spec()` | Parse OpenAPI/Swagger to tibble spec | Already handles both Swagger 2.0 and OpenAPI 3.0, accepts file paths or parsed objects |
| `preprocess_schema()` | Filter endpoints before parsing | Accepts `exclude_endpoints` parameter for per-schema customization |
| `render_endpoint_stubs()` | Generate R function code from spec | Used by all three generators, config-driven |
| `here::here()` | Path resolution | Standard R practice for portable paths |
| `purrr::map()` + `list_rbind()` | Iterate and combine specs | Tidyverse idiom already used in ct/cc generators |

### Supporting Tools
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `file.copy()` | Create baseline for diffing | Stub verification (pattern from Phase 9) |
| `list.files()` | Find schema files by pattern | File selection (already used in all generators) |
| `cli::cli_*()` | User feedback | Logging and progress reporting |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extract function | Inline duplication | Inline = more maintainable for one-off patterns; function = better when pattern repeats 3+ times |
| Shared helper | Per-schema logic | Helper adds indirection but eliminates 3-way duplication |

## Architecture Patterns

### Current Architecture (Before Refactoring)

```
generate_stubs.R
├── generate_ct_stubs()
│   ├── list.files(pattern = "^ctx-.*-prod.json$")
│   ├── map(files, ~ fromJSON() %>% openapi_to_spec())
│   └── post-process spec → render
│
├── generate_chemi_stubs()
│   ├── list.files(pattern = "^chemi-.*\\.json$")  [duplicated check]
│   ├── parse_chemi_schemas()  [delegation]
│   │   ├── list.files() + filter (stage-based selection)
│   │   ├── map(files, ~ fromJSON() %>% openapi_to_spec())
│   │   └── add source_file column
│   ├── filter(ENDPOINT_PATTERNS_TO_EXCLUDE)  [post-parsing filter]
│   └── post-process spec → render
│
└── generate_cc_stubs()
    ├── list.files(pattern = "^commonchemistry-prod.json$")
    ├── map(files, ~ fromJSON() %>% openapi_to_spec())
    └── post-process spec → render
```

**Divergence points:**
1. **File selection:** chemi has stage-based selection logic (prod > staging > dev); ct/cc filter by exact filename pattern
2. **Parsing entry point:** chemi calls `parse_chemi_schemas()`, ct/cc call `openapi_to_spec()` directly
3. **Filtering location:** chemi filters routes after parsing; ct/cc rely on `openapi_to_spec(preprocess=TRUE)` default

### Pattern 1: Unified Generator Function Pattern (Target Architecture)

**What:** All three generators follow identical structure with schema-specific configuration.

**Recommended structure:**
```r
# Shared file selection helper
select_schema_files <- function(pattern, stage_priority = NULL, exclude_pattern = NULL) {
  files <- list.files(here::here("schema"), pattern = pattern, full.names = FALSE)

  if (!is.null(exclude_pattern)) {
    files <- files[!grepl(exclude_pattern, files, ignore.case = TRUE)]
  }

  # Stage-based selection (if stage_priority provided)
  if (!is.null(stage_priority)) {
    # Parse filenames: {prefix}-{domain}-{stage}.json
    # Select best stage per domain
    # (extract logic from parse_chemi_schemas lines 648-668)
  }

  files
}

# Unified generator pattern
generate_X_stubs <- function() {
  cli_h2("{Schema Type} ({prefix}_*)")

  # 1. Select schema files (schema-specific logic)
  schema_files <- select_schema_files(
    pattern = config$pattern,
    stage_priority = config$stage_priority,
    exclude_pattern = config$exclude_pattern
  )

  if (length(schema_files) == 0) {
    cli_alert_warning("No schema files found, skipping")
    return(empty_result)
  }

  # 2. Parse schemas (UNIFIED - all use openapi_to_spec)
  endpoints <- map(
    schema_files,
    ~ {
      openapi <- jsonlite::fromJSON(here::here('schema', .x), simplifyVector = FALSE)
      openapi_to_spec(openapi, preprocess = FALSE)  # control preprocessing explicitly
    }
  ) %>% list_rbind()

  # 3. Apply endpoint filters (schema-specific exclusions)
  if (!is.null(config$exclude_endpoints)) {
    endpoints <- endpoints %>% filter(!str_detect(route, config$exclude_endpoints))
  }

  # 4. Post-process spec (schema-specific transformations)
  endpoints <- endpoints %>%
    mutate(
      route = strip_curly_params(route, leading_slash = 'remove'),
      # ... schema-specific column derivations
    )

  # 5. Find missing endpoints and render stubs
  # ... (existing logic unchanged)
}
```

**Key principles:**
- **Same entry point:** All call `openapi_to_spec()` directly (not via `parse_chemi_schemas()`)
- **Explicit preprocessing:** Set `preprocess=FALSE`, apply filtering after parsing with per-schema exclusions
- **Config-driven differences:** File patterns, stage priority, exclusion patterns come from config
- **Shared helpers:** File selection and filtering logic extracted to reusable functions

### Pattern 2: Per-Schema Configuration

**What:** Schema-specific options in config lists or centralized config module.

**Option A: Inline config in generate_stubs.R**
```r
# At top of generate_stubs.R, add schema parsing configs
ct_schema_config <- list(
  pattern = "^ctx-.*-prod\\.json$",
  stage_priority = NULL,  # no stage selection
  exclude_pattern = NULL,
  exclude_endpoints = NULL  # uses openapi_to_spec default preprocessing
)

chemi_schema_config <- list(
  pattern = "^chemi-.*\\.json$",
  stage_priority = c("prod", "staging", "dev"),
  exclude_pattern = "ui",
  exclude_endpoints = ENDPOINT_PATTERNS_TO_EXCLUDE  # explicit post-filter
)

cc_schema_config <- list(
  pattern = "^commonchemistry-prod\\.json$",
  stage_priority = NULL,
  exclude_pattern = NULL,
  exclude_endpoints = NULL
)
```

**Option B: Add to 00_config.R**
```r
# In dev/endpoint_eval/00_config.R
SCHEMA_CONFIGS <- list(
  ct = list(pattern = "^ctx-.*-prod\\.json$", ...),
  chemi = list(pattern = "^chemi-.*\\.json$", stage_priority = c("prod", "staging", "dev"), ...),
  cc = list(pattern = "^commonchemistry-prod\\.json$", ...)
)
```

**Recommendation:** Option A (inline) for now. Config is specific to stub generation, not general utilities.

### Pattern 3: Stub Verification via Baseline Diff

**What:** Copy existing stubs to baseline, regenerate, compare.

**When to use:** Validating that refactored code produces identical output.

**Example (from Phase 9):**
```r
# Before regeneration
dir.create(".baseline/stubs", recursive = TRUE, showWarnings = FALSE)
stub_files <- list.files("R", pattern = "^chemi_.*\\.R$", full.names = TRUE)
file.copy(stub_files, ".baseline/stubs/", overwrite = TRUE)

# After regeneration
# Manual diff (git diff, diffuse, or R tools::Rdiff)
# Acceptable differences: improved body extraction, better parameter handling
# Unacceptable differences: missing endpoints, broken syntax
```

**Note:** User specified "improvements OK" - new stubs from better body extraction are acceptable differences, not failures.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema file selection with stage priority | Custom file sorting logic | Extract from `parse_chemi_schemas()` (lines 648-668) | Already tested, handles edge cases (missing stages, filename parsing) |
| OpenAPI version detection | Manual swagger/openapi field checks | `detect_schema_version()` (01_schema_resolution.R) | Already handles Swagger 2.0 vs OpenAPI 3.0, wired into `openapi_to_spec()` |
| Endpoint filtering | String matching in generator | `preprocess_schema()` with `exclude_endpoints` param | Centralized, testable, reusable |
| Path building | String concatenation | `here::here()` | Portable across Windows/Unix, handles workspace root detection |
| Stub diffing | Custom file comparison | `file.copy()` to baseline + manual `git diff` | Simple, visual, works with existing git workflow |

**Key insight:** `parse_chemi_schemas()` contains two separable concerns: (1) file selection logic (stage-based), (2) OpenAPI parsing. Only (1) is unique to chemi; (2) is redundant with `openapi_to_spec()`.

## Common Pitfalls

### Pitfall 1: Breaking chemi stage-based file selection

**What goes wrong:** Naively deleting `parse_chemi_schemas()` loses the prod > staging > dev prioritization logic.

**Why it happens:** The stage selection code (lines 648-668) is buried inside `parse_chemi_schemas()`, not in a reusable helper.

**How to avoid:**
1. Extract stage selection logic into `select_schema_files()` helper
2. Test that chemi still selects prod over staging when both exist
3. Verify source_file column still populated (used for debugging)

**Warning signs:**
- Chemi generator starts parsing multiple stages for same domain
- Duplicate endpoints in chemi spec tibble
- Missing source_file column in debug output

### Pitfall 2: Inconsistent endpoint filtering

**What goes wrong:** After refactoring, some schemas filter endpoints, others don't, leading to inconsistent stub coverage.

**Why it happens:** Current code mixes filtering strategies:
- ct/cc: `openapi_to_spec(preprocess=TRUE)` filters during parsing
- chemi: Filters after parsing with `!str_detect(route, ENDPOINT_PATTERNS_TO_EXCLUDE)`

**How to avoid:**
1. Explicitly set `preprocess=FALSE` for all generators
2. Apply filtering after parsing in consistent location
3. Support per-schema exclusion overrides (e.g., `ENDPOINT_PATTERNS_TO_EXCLUDE_CHEMI`)
4. Document filtering strategy in comments

**Warning signs:**
- Different endpoint counts before/after refactoring
- Preflight/metadata endpoints appearing in specs
- Test failures about skipped endpoints

### Pitfall 3: Lost preprocessing benefits

**What goes wrong:** Setting `preprocess=FALSE` to control filtering loses schema component filtering (reduces schema complexity).

**Why it happens:** `preprocess_schema()` does two things: (1) filter endpoints, (2) filter unused schema components. Disabling preprocessing loses both.

**How to avoid:**
- **Option A (recommended):** Keep `preprocess=TRUE` default, rely on `ENDPOINT_PATTERNS_TO_EXCLUDE` global config, add per-schema post-filters only for exceptions
- **Option B:** Call `preprocess_schema()` manually with custom exclusions before `openapi_to_spec()`

**Recommendation:** Use Option A. The global exclusion pattern works for 95% of cases. Only chemi might need post-filtering (if schemas have chemi-specific bad endpoints).

**Warning signs:**
- Increased memory usage during parsing
- Circular reference warnings
- Slower parsing times

### Pitfall 4: Regression in Swagger 2.0 body extraction

**What goes wrong:** Refactored code breaks body parameter extraction for chemi schemas (Swagger 2.0).

**Why it happens:** `openapi_to_spec()` handles Swagger 2.0 vs OpenAPI 3.0 differently via `detect_schema_version()`. If preprocessing or parsing order changes, body extraction might fail.

**How to avoid:**
1. Verify `openapi_to_spec()` is called on parsed JSON (not file paths) to allow `preprocess=FALSE`
2. Check that `has_body` and `body_params` columns are populated for POST endpoints
3. Run Phase 9 verification tests after refactoring
4. Spot-check AMOS/RDKit stubs for `options = list(...)` parameters

**Warning signs:**
- Chemi stubs missing `options` parameter in POST functions
- `has_body=FALSE` for endpoints that should have bodies
- Empty `body_params` strings in spec tibble

### Pitfall 5: Top-to-bottom script execution broken

**What goes wrong:** Script fails when sourced due to missing variables or out-of-order execution.

**Why it happens:** Current script has self-contained generator functions that work independently. Refactoring might introduce shared state or assume specific execution order.

**How to avoid:**
1. Keep generator functions self-contained (no shared mutable state)
2. Test with `source("dev/generate_stubs.R")` after each change
3. Ensure helper functions defined before first use
4. Reset tracking state between generators (`reset_endpoint_tracking()`)

**Warning signs:**
- "Object not found" errors when sourcing
- Different results when running generators in different order
- Leaked state from one generator affecting another

## Code Examples

### Extracting Stage-Based File Selection

Based on `parse_chemi_schemas()` lines 648-668:

```r
# Source: dev/endpoint_eval/04_openapi_parser.R (parse_chemi_schemas function)
# Extract this logic into shared helper

select_schema_files <- function(
  schema_dir = NULL,
  pattern = "^chemi-.*\\.json$",
  exclude_pattern = "ui",
  stage_priority = c("prod", "staging", "dev")
) {
  if (is.null(schema_dir)) schema_dir <- here::here("schema")

  # List files
  all_files <- list.files(path = schema_dir, pattern = pattern, full.names = FALSE)

  # Filter excluded
  if (!is.null(exclude_pattern) && nzchar(exclude_pattern)) {
    files <- all_files[!grepl(exclude_pattern, all_files, ignore.case = TRUE)]
  } else {
    files <- all_files
  }

  # Stage-based selection (if stage_priority provided)
  if (!is.null(stage_priority) && length(files) > 0) {
    # Parse filenames: {prefix}-{domain}-{stage}.json
    schema_meta <- tibble::tibble(file = files) %>%
      tidyr::separate_wider_delim(
        cols = file,
        delim = "-",
        names = c("origin", "domain", "stage"),
        cols_remove = FALSE
      ) %>%
      dplyr::mutate(
        stage = stringr::str_remove(stage, "\\.json$"),
        stage = factor(stage, levels = stage_priority)
      )

    # Select best stage per domain
    files <- schema_meta %>%
      dplyr::group_by(domain) %>%
      dplyr::arrange(stage, .by_group = TRUE) %>%
      dplyr::slice(1) %>%
      dplyr::ungroup() %>%
      dplyr::pull(file)
  }

  files
}
```

### Unified Generator Pattern

```r
# Source: Pattern extracted from generate_ct_stubs() and generate_cc_stubs()
# Adapt for all three generators with config-driven differences

generate_X_stubs <- function(schema_config, stub_config) {
  cli_h2("{schema_config$name} ({schema_config$prefix}_*)")

  # 1. Select schema files
  schema_files <- select_schema_files(
    pattern = schema_config$pattern,
    exclude_pattern = schema_config$exclude_pattern,
    stage_priority = schema_config$stage_priority
  )

  if (length(schema_files) == 0) {
    cli_alert_warning("No schema files found, skipping")
    return(tibble(action = character(), file = character()))
  }

  cli_alert_info("Found {length(schema_files)} schema file(s)")

  # 2. Parse all schemas with openapi_to_spec
  endpoints <- map(
    schema_files,
    ~ {
      openapi <- jsonlite::fromJSON(here::here('schema', .x), simplifyVector = FALSE)
      spec <- openapi_to_spec(openapi)
      spec$source_file <- .x  # Add traceability
      spec
    },
    .progress = FALSE
  ) %>% list_rbind()

  # 3. Apply schema-specific endpoint filters
  if (!is.null(schema_config$exclude_endpoints)) {
    endpoints <- endpoints %>%
      filter(!str_detect(route, schema_config$exclude_endpoints))
  }

  # 4. Post-process spec (schema-specific mutations)
  endpoints <- schema_config$post_process(endpoints)

  cli_alert_info("Parsed {nrow(endpoints)} endpoint(s)")

  # 5. Find missing endpoints
  res <- find_endpoint_usages_base(
    endpoints$route,
    pkg_dir = here::here("R"),
    files_regex = schema_config$files_regex,
    expected_files = endpoints$file
  )

  endpoints_to_build <- endpoints %>%
    filter(route %in% {res$summary %>% filter(n_hits == 0) %>% pull(endpoint)})

  if (nrow(endpoints_to_build) == 0) {
    cli_alert_success("All {schema_config$prefix}_* endpoints already implemented")
    return(tibble(action = character(), file = character()))
  }

  # 6. Generate and write stubs
  cli_alert_info("Found {nrow(endpoints_to_build)} endpoint(s) to generate")
  spec_with_text <- render_endpoint_stubs(endpoints_to_build, config = stub_config)

  # 7. Aggregate if needed (chemi has multiple functions per file)
  if (schema_config$aggregate_by_file) {
    spec_with_text <- spec_with_text %>%
      group_by(file) %>%
      summarise(text = paste(text, collapse = "\n\n"), .groups = "drop")
  }

  scaffold_files(spec_with_text, base_dir = "R", overwrite = TRUE, append = TRUE, quiet = TRUE)
}
```

### Baseline Diff for Verification

```r
# Source: dev/endpoint_eval/verify_phase9.R (lines 22-57)
# Pattern for stub verification

# Before refactoring - save baseline
baseline_dir <- ".baseline/stubs"
dir.create(baseline_dir, recursive = TRUE, showWarnings = FALSE)

ct_files <- list.files("R", pattern = "^ct_.*\\.R$", full.names = TRUE)
chemi_files <- list.files("R", pattern = "^chemi_.*\\.R$", full.names = TRUE)
cc_files <- list.files("R", pattern = "^cc_.*\\.R$", full.names = TRUE)

file.copy(c(ct_files, chemi_files, cc_files), baseline_dir, overwrite = TRUE)
cli_alert_success("Copied {length(ct_files) + length(chemi_files) + length(cc_files)} stubs to baseline")

# After refactoring - regenerate and compare
# source("dev/generate_stubs.R")  # Regenerate with refactored code

# Manual diff (use git, diffuse, or tools::Rdiff)
# Example: git diff .baseline/stubs/ R/
# Acceptable: new functions, improved body params, better roxygen
# Unacceptable: missing functions, syntax errors, broken imports
```

## State of the Art

### R Pipeline Refactoring (2026 Standards)

Based on [From scripts to pipelines in the age of LLMs (R-bloggers, Jan 2026)](https://www.r-bloggers.com/2026/01/from-scripts-to-pipelines-in-the-age-of-llms/), modern R pipelines emphasize:

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Monolithic scripts with numbered prefixes | Modular functions with explicit dependencies | Better testability, reusability |
| Ad-hoc file selection in each script | Shared helper functions for common operations | DRY principle, reduced duplication |
| Implicit execution order | Self-documenting, sourceable top-to-bottom | Easier to maintain, debug |
| Mixed concerns (selection + processing) | Separated concerns (select files → parse → process) | Single Responsibility Principle |

**Application to this phase:**
- Extract file selection logic (separates concerns)
- Make all generators follow same pattern (DRY)
- Keep script sourceable top-to-bottom (no side effects in helpers)
- Use config objects for schema-specific differences (explicit over implicit)

### Refactoring Best Practices

Key principles from [Code Refactoring Best Practices (Multiple Sources, 2026)](https://refactoring.guru/smells/duplicate-code):

**Extract Method:** Pull duplicate code into shared function - applies to file selection and filtering logic

**Consolidate Conditional Expression:** If multiple generators do the same checks, merge into single pattern with config-driven differences

**Incremental Refactoring:** Change one generator at a time, verify, then move to next

**Test-Driven:** Save baseline before refactoring, verify output matches after

## Open Questions

1. **Should `parse_chemi_schemas()` be deleted or deprecated?**
   - What we know: Function is only called from `generate_chemi_stubs()` (line 183)
   - What's unclear: External usage outside this codebase (unlikely, in dev/ directory)
   - Recommendation: Delete entirely. It's a dev utility, not exported API. Extract useful stage-selection logic into new helper.

2. **Where should per-schema endpoint exclusions be defined?**
   - What we know: `ENDPOINT_PATTERNS_TO_EXCLUDE` is global in 00_config.R
   - What's unclear: Whether chemi needs different exclusions than ct/cc
   - Recommendation: Start with global pattern for all schemas. Add per-schema overrides (e.g., `ENDPOINT_PATTERNS_TO_EXCLUDE_CHEMI`) only if needed. Current code suggests chemi uses same exclusions.

3. **Should preprocessing be enabled or disabled in refactored code?**
   - What we know: `openapi_to_spec(preprocess=TRUE)` filters endpoints AND schema components
   - What's unclear: Whether component filtering is needed or just endpoint filtering
   - Recommendation: Keep `preprocess=TRUE` (the default). It's beneficial and already tested. Only override with `preprocess=FALSE` if per-schema exclusions conflict with global pattern.

4. **How to handle "improvements OK" in verification?**
   - What we know: User said acceptable differences = new stubs from better body extraction
   - What's unclear: How to programmatically distinguish "improvement" from "regression"
   - Recommendation: Manual review of diff. Improvements = more parameters, better roxygen, new functions. Regressions = missing functions, broken syntax, fewer parameters. Use spot-checking, not automated equality.

## Sources

### Primary (HIGH confidence)
- C:\Users\sxthi\Documents\ComptoxR\dev\generate_stubs.R - Current implementation (lines 88-333)
- C:\Users\sxthi\Documents\ComptoxR\dev\endpoint_eval\04_openapi_parser.R - `parse_chemi_schemas()` function (lines 598-690), `openapi_to_spec()` (lines 322-450)
- C:\Users\sxthi\Documents\ComptoxR\dev\endpoint_eval\01_schema_resolution.R - `preprocess_schema()` (lines 48-66), `detect_schema_version()` (lines 251-262)
- C:\Users\sxthi\Documents\ComptoxR\dev\endpoint_eval\00_config.R - `ENDPOINT_PATTERNS_TO_EXCLUDE` (line 41)
- C:\Users\sxthi\Documents\ComptoxR\dev\endpoint_eval\verify_phase9.R - Baseline diff pattern (lines 22-57)

### Secondary (MEDIUM confidence)
- [From scripts to pipelines in the age of LLMs | R-bloggers](https://www.r-bloggers.com/2026/01/from-scripts-to-pipelines-in-the-age-of-llms/) - Modern R pipeline patterns (2026)
- [Duplicate Code | Refactoring.Guru](https://refactoring.guru/smells/duplicate-code) - Extract Method refactoring pattern
- [Code Refactoring Best Practices | Mad Devs](https://maddevs.io/blog/code-refactoring/) - Incremental refactoring approach
- [Building Data Pipelines with {targets} | Reproducible Medical Research](https://bookdown.org/pdr_higgins/rmrwr/building-data-pipelines-with-targets.html) - Modular function-based pipeline design

### Tertiary (LOW confidence)
- WebSearch results on R refactoring - General principles, not R-specific validation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using existing codebase functions, no external dependencies
- Architecture patterns: HIGH - Analyzed existing code, clear duplication patterns identified
- Pitfalls: HIGH - Based on current divergent implementations and known issues (filtering, Swagger 2.0 support)
- Code examples: HIGH - Extracted from actual codebase functions

**Research date:** 2026-01-29
**Valid until:** 2026-02-28 (30 days - stable refactoring patterns, no fast-moving tech)

**Key constraints from CONTEXT.md:**
- Top-to-bottom script execution (user requirement)
- Claude's discretion on parse_chemi_schemas() handling (delete vs keep)
- Claude's discretion on exact config structure
- Improvements OK in stub diffs (not regressions)
- GH Action alignment deferred to follow-up (not this phase)
