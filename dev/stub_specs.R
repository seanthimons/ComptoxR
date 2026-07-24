# ==============================================================================
# Stub Specs & Endpoint Coverage (sourceable module, no side effects)
# ==============================================================================
#
# Shared by:
#   - dev/generate_stubs.R    -> stub generation (run_generator + ct/chemi specs)
#   - dev/calculate_coverage.R -> operation-level API coverage (endpoint_coverage)
#
# Sourcing this file only LOADS utilities and DEFINES objects (configs, specs,
# helpers). It does not generate stubs, reset tracking state, or write files, so
# it is safe to source from any consumer. The per-API build_endpoints() closures
# are the single source of truth for how (route, method) pairs map to file/fn
# names, so coverage is measured against the exact same endpoint set the stub
# generator builds.

# Load required packages
suppressPackageStartupMessages({
  library(jsonlite)
  library(tidyverse)
  library(here)
  library(cli)
})

# ==============================================================================
# Configuration
# ==============================================================================

# CompTox (ct_*) function generation configuration
ct_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# Cheminformatics (chemi_*) function generation configuration
chemi_config <- list(
  wrapper_function = "generic_chemi_request",
  param_strategy = "options",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# ==============================================================================
# Load Utilities
# ==============================================================================

cli_alert_info("Loading endpoint evaluation utilities...")

# Source the modular utilities
utils_dir <- here::here("dev", "endpoint_eval")

source(file.path(utils_dir, "00_config.R"))
source(file.path(utils_dir, "01_schema_resolution.R"))
source(file.path(utils_dir, "02_path_utils.R"))
source(file.path(utils_dir, "03_codebase_search.R"))
source(file.path(utils_dir, "04_openapi_parser.R"))
source(file.path(utils_dir, "05_file_scaffold.R"))
source(file.path(utils_dir, "06_param_parsing.R"))
source(file.path(utils_dir, "07_stub_generation.R"))
source(file.path(utils_dir, "08_drift_detection.R"))

# ==============================================================================
# Generic Runner
# ==============================================================================
# The active APIs (ct/chemi) share one pipeline. Only three things vary per
# API: which schema files to read, how routes map to file/fn names, and an
# optional route filter. Those live in each spec's `build_endpoints()` closure
# (preserved verbatim from the original per-API functions). Everything from
# usage detection onward is identical and lives here, in run_generator().
#
# Note: select_schema_files() lives in dev/endpoint_eval/01_schema_resolution.R
# for shared use between generate_stubs.R and diff_schemas.R.

empty_scaffold <- function() tibble(action = character(), file = character())

# ==============================================================================
# Collision-only disambiguation (issue #214)
# ==============================================================================
# The route -> file/fn derivation strips distinguishing tokens (summary,
# by-dtxsid, trailing-slash, path-params), so several DISTINCT (route, method)
# pairs can collapse to one file + fn. The append-only scaffold then writes all
# defs and the LAST one wins, silently dropping the earlier, richer definitions.
#
# Fix: compute BOTH the existing "short" file/fn and a "full" file/fn that keeps
# the distinguishing tokens. Where a short fn is unique we keep it (idempotent);
# only the rows whose short fn collides (>= 2 distinct route+method map to it)
# fall back to the full name so every endpoint gets a unique file + fn.

#' Derive the per-row function name from a file column using the existing
#' bulk/method-suffix convention (grouped per file). Returns a character vector
#' aligned with the input rows.
derive_fn_from_file <- function(df, file_col) {
  df %>%
    mutate(.fn_file = .data[[file_col]]) %>%
    group_by(.fn_file) %>%
    mutate(
      .mc = n(),
      .fn = case_when(
        .mc == 1 ~ tools::file_path_sans_ext(basename(.fn_file)),
        method == "GET" ~ tools::file_path_sans_ext(basename(.fn_file)),
        method == "POST" ~ paste0(tools::file_path_sans_ext(basename(.fn_file)), "_bulk"),
        .default = paste0(tools::file_path_sans_ext(basename(.fn_file)), "_", tolower(method))
      )
    ) %>%
    ungroup() %>%
    pull(.fn)
}

#' Collision-only fallback. Expects columns file_short/file_full/fn_short/fn_full.
#' Keeps the short names where the short fn is unique; rows whose short fn
#' collides fall back to the full file/fn. Drops all helper columns (file_short,
#' file_full, fn_short, fn_full, and any starting with ".").
resolve_collisions <- function(df) {
  df %>%
    add_count(fn_short, name = "n_short_count") %>%
    mutate(
      file = if_else(n_short_count > 1, file_full, file_short),
      fn = if_else(n_short_count > 1, fn_full, fn_short)
    ) %>%
    select(
      -any_of(c("file_short", "file_full", "fn_short", "fn_full", "n_short_count")),
      -starts_with(".")
    )
}

#' Run the shared stub-generation pipeline for one API spec.
#' @param spec list with prefix, heading, build_endpoints(), config, and
#'   optional post() hook.
#' @return list(scaffold = <scaffold tibble>, drift = <drift tibble>)
run_generator <- function(spec) {
  cli_h2(spec$heading)

  endpoints <- spec$build_endpoints()

  if (is.null(endpoints) || nrow(endpoints) == 0) {
    return(list(scaffold = empty_scaffold(), drift = tibble()))
  }

  # Find missing endpoints
  res <- find_endpoint_usages_base(
    endpoints$route,
    pkg_dir = here::here("R"),
    files_regex = sprintf("^%s_.*\\.R$", spec$prefix),
    expected_files = endpoints$file
  )

  # Detect parameter drift for existing endpoints
  drift <- detect_parameter_drift(
    endpoints = endpoints,
    usage_summary = res$summary %>% filter(n_hits > 0),
    pkg_dir = here::here("R")
  )

  endpoints_to_build <- endpoints %>%
    filter(
      route %in%
        {
          res$summary %>% filter(n_hits == 0) %>% pull(endpoint)
        }
    )

  if (nrow(endpoints_to_build) == 0) {
    cli_alert_success("All {spec$prefix}_* endpoints already implemented")
    return(list(scaffold = empty_scaffold(), drift = drift))
  }

  cli_alert_info("Found {nrow(endpoints_to_build)} endpoint(s) to generate")

  # Generate stubs
  spec_with_text <- render_endpoint_stubs(endpoints_to_build, config = spec$config)

  # Empty check must precede spec$post(): a zero-row render result has no
  # columns, and post hooks (e.g. chemi's group_by(file)) error on it.
  if (nrow(spec_with_text) == 0) {
    cli_alert_warning("No {spec$prefix} stubs generated (all skipped)")
    return(list(scaffold = empty_scaffold(), drift = drift))
  }

  # Optional per-API post-processing (e.g. chemi aggregates by file)
  if (!is.null(spec$post)) {
    spec_with_text <- spec$post(spec_with_text)
  }

  list(
    scaffold = scaffold_files(spec_with_text, base_dir = "R", overwrite = FALSE, append = TRUE, quiet = TRUE),
    drift = drift
  )
}

# ==============================================================================
# Per-API Specs
# ==============================================================================
# Each build_endpoints() is the original per-API function's parse + derive logic
# verbatim; it returns the endpoints tibble (or NULL when no schemas/endpoints).

ct_spec <- list(
  prefix = "ct",
  heading = "CompTox Dashboard (ct_*)",
  config = ct_config,
  build_endpoints = function() {
    ctx_schema_files <- list.files(
      path = here::here('schema'),
      pattern = "^ctx-.*-prod\\.json$",
      full.names = FALSE
    )

    if (length(ctx_schema_files) == 0) {
      cli_alert_warning("No ctx schema files found, skipping ct_* generation")
      return(NULL)
    }

    cli_alert_info("Found {length(ctx_schema_files)} ctx schema file(s)")

    endpoints <- map(
      ctx_schema_files,
      ~ {
        openapi <- jsonlite::fromJSON(here::here('schema', .x), simplifyVector = FALSE)
        openapi_to_spec(openapi)
      },
      .progress = FALSE
    ) %>%
      list_rbind() %>%
      mutate(
        route = strip_curly_params(route, leading_slash = 'remove'),
        domain = route %>% str_extract("^[^/]+"),
        # "short" core: strips domain-ish noise AND the distinguishing tokens
        # (summary, by-dtxsid). This is today's logic, kept for idempotency.
        .core_short = route %>%
          str_remove_all(regex(
            "(?i)(?:^|[/_-])(?:hazards?|chemical?|exposures?|bioactivit(?:y|ies)|summary|by[/_-]dtxsid)(?=$|[/_-])"
          )) %>%
          str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>%
          str_replace_all("[/]+", " ") %>%
          str_squish() %>%
          str_replace_all("\\s", "_") %>%
          str_replace_all("-", "_"),
        # "full" core: strips ONLY the domain-ish noise, retaining the
        # distinguishing tokens (summary, by-dtxsid, by-aeid) so colliding
        # endpoints get unique names.
        .core_full = route %>%
          str_remove_all(regex(
            "(?i)(?:^|[/_-])(?:hazards?|chemical?|exposures?|bioactivit(?:y|ies))(?=$|[/_-])"
          )) %>%
          str_replace_all("[/]+", " ") %>%
          str_squish() %>%
          str_replace_all("\\s", "_") %>%
          str_replace_all("-", "_"),
        file_short = paste0("ct_", domain, "_", .core_short, ".R"),
        file_full = paste0("ct_", domain, "_", .core_full, ".R"),
        batch_limit = case_when(
          method == 'GET' & !is.na(num_path_params) & num_path_params > 0 ~ 1,
          method == 'GET' & !is.na(num_path_params) & num_path_params == 0 ~ 0,
          .default = NULL
        )
      ) %>%
      arrange(forcats::fct_inorder(domain), route, factor(method, levels = c('POST', 'GET'))) %>%
      distinct(route, method, .keep_all = TRUE)

    endpoints$fn_short <- derive_fn_from_file(endpoints, "file_short")
    endpoints$fn_full <- derive_fn_from_file(endpoints, "file_full")
    endpoints <- resolve_collisions(endpoints)

    cli_alert_info("Parsed {nrow(endpoints)} endpoint(s) from schemas")
    endpoints
  }
)

chemi_spec <- list(
  prefix = "chemi",
  heading = "Cheminformatics (chemi_*)",
  config = chemi_config,
  build_endpoints = function() {
    # Select schema files with stage prioritization
    chemi_schema_files <- select_schema_files(
      pattern = "^chemi-.*\\.json$",
      exclude_pattern = "ui",
      stage_priority = c("prod", "staging", "dev")
    )

    if (length(chemi_schema_files) == 0) {
      cli_alert_warning("No chemi schema files found, skipping chemi_* generation")
      return(NULL)
    }

    cli_alert_info("Found {length(chemi_schema_files)} chemi schema file(s)")

    # openapi_to_spec handles both Swagger 2.0 (amos, rdkit, mordred) and OpenAPI 3.0,
    # the same way generate_ct_stubs and generate_cc_stubs do (v1.6 UNIFY-CHEMI).
    chemi_endpoints <- tryCatch(
      {
        ep <- map(
          chemi_schema_files,
          ~ {
            openapi <- jsonlite::fromJSON(here::here('schema', .x), simplifyVector = FALSE)
            spec <- openapi_to_spec(openapi)
            spec$source_file <- .x
            spec
          },
          .progress = FALSE
        ) %>%
          list_rbind() %>%
          filter(
            str_detect(method, 'GET|POST'),
            !str_detect(route, ENDPOINT_PATTERNS_TO_EXCLUDE) # Exclude admin/UI routes
          ) %>%
          mutate(
            route = strip_curly_params(route, leading_slash = 'remove'),
            # Extract service slug from source filename (e.g., "chemi-chet-dev.json" -> "chet")
            service_slug = source_file %>% str_extract("^chemi-([^-]+)") %>% str_remove("^chemi-"),
            # Use route domain when route has api/ prefix, otherwise fall back to service slug
            domain = if_else(
              str_starts(route, "api/"),
              route %>% str_remove("^api/") %>% str_extract("^[^/]+"),
              service_slug
            ),
            name = route %>%
              str_remove_all("^api/") %>%
              str_remove_all(regex("(?i)(?:^|[/_-])(?:chemi|search(?:es)?|summary|by[/_-]dtxsid)(?=$|[/_-])")) %>%
              str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>%
              str_replace_all("[/]+", " ") %>%
              str_squish() %>%
              str_replace_all("\\s", "_") %>%
              str_replace_all("-", "_"),
            # First path-param name, used as a disambiguating marker for
            # trailing-slash / path-param GET variants that share a short name.
            .first_pp = path_params %>%
              str_extract("^[^,]+") %>%
              str_replace_all("[^A-Za-z0-9]+", "_") %>%
              str_to_lower() %>%
              coalesce(""),
            .name_full = if_else(
              num_path_params > 0 & nzchar(.first_pp) & !str_detect(name, fixed(.first_pp)),
              paste0(name, "_by_", .first_pp),
              name
            ),
            file_short = case_when(
              nchar(name) == 0 ~ paste0("chemi_", domain, ".R"),
              str_detect(name, pattern = domain) ~ paste0("chemi_", name, ".R"),
              .default = paste0("chemi_", domain, "_", name, ".R")
            ),
            file_full = case_when(
              nchar(.name_full) == 0 ~ paste0("chemi_", domain, ".R"),
              str_detect(.name_full, pattern = domain) ~ paste0("chemi_", .name_full, ".R"),
              .default = paste0("chemi_", domain, "_", .name_full, ".R")
            ),
            batch_limit = 0,
            route = str_remove_all(route, "^api/")
          ) %>%
          distinct(route, method, .keep_all = TRUE)

        ep$fn_short <- derive_fn_from_file(ep, "file_short")
        ep$fn_full <- derive_fn_from_file(ep, "file_full")
        resolve_collisions(ep)
      },
      error = function(e) {
        cli_alert_warning("Error parsing chemi schemas: {e$message}")
        return(tibble())
      }
    )

    if (nrow(chemi_endpoints) == 0) {
      cli_alert_warning("No chemi endpoints parsed")
      return(NULL)
    }

    cli_alert_info("Parsed {nrow(chemi_endpoints)} endpoint(s) from schemas")
    chemi_endpoints
  },
  # Aggregate by file (multiple functions per file) before scaffolding.
  post = function(spec_with_text) {
    spec_with_text %>%
      group_by(file) %>%
      summarise(text = paste(text, collapse = "\n\n"), .groups = "drop")
  }
)

api_specs <- list(ct = ct_spec, chemi = chemi_spec)

# ==============================================================================
# Operation-level Coverage
# ==============================================================================
# Coverage = (implemented operations) / (total operations), where an "operation"
# is one (route, method) row from a spec's build_endpoints(). Because that set is
# the exact input the stub generator builds against, coverage is a subset over
# its superset and therefore always <= 100% (no artificial cap needed). GET and
# POST on the same route are distinct operations with distinct fn names
# (base vs *_bulk), so they are counted per row by the operation's own fn.

#' Is a single (route, method) operation implemented?
#'
#' True when the expected wrapper file exists and defines the expected function.
#' Mirrors the file-existence + function-definition check that
#' find_endpoint_usages_base() uses as its fallback, applied per operation so
#' GET/POST wrappers sharing one file are distinguished by their fn name.
#'
#' @param file Expected wrapper filename (basename, e.g. "ct_chemical_detail_search.R")
#' @param fn Expected function name (e.g. "ct_chemical_detail_search" or "..._bulk")
#' @param pkg_dir Directory containing the R source files
#' @return Logical scalar
is_operation_implemented <- function(file, fn, pkg_dir) {
  path <- file.path(pkg_dir, file)
  if (!file.exists(path)) {
    return(FALSE)
  }
  lines <- tryCatch(readLines(path, warn = FALSE), error = function(e) character())
  pattern <- sprintf("^\\s*%s\\s*(<-|=)\\s*function\\b", gsub("\\.", "\\\\.", fn))
  any(grepl(pattern, lines))
}

#' Operation-level coverage for one API spec.
#'
#' @param spec One of ct_spec / chemi_spec.
#' @param pkg_dir Directory containing the R source files (default R/).
#' @return list(total = <int>, covered = <int>)
endpoint_coverage <- function(spec, pkg_dir = here::here("R")) {
  eps <- spec$build_endpoints()
  if (is.null(eps) || nrow(eps) == 0) {
    return(list(total = 0L, covered = 0L))
  }
  covered <- sum(vapply(
    seq_len(nrow(eps)),
    function(i) is_operation_implemented(eps$file[i], eps$fn[i], pkg_dir),
    logical(1)
  ))
  list(total = nrow(eps), covered = as.integer(covered))
}
