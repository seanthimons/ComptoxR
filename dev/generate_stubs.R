#!/usr/bin/env Rscript
# ==============================================================================
# Automated Function Stub Generation for CI
# ==============================================================================
#
# This script generates R function stubs from OpenAPI schemas for active APIs:
#   - CompTox Dashboard (ct_*)
#   - Cheminformatics (chemi_*)
#
# Designed to be run in CI after schema downloads to automatically create
# function stubs for any new or changed API endpoints.
#
# Usage:
#   Rscript dev/generate_stubs.R
#
# Output:
#   - New function stubs in R/ directory
#   - Summary statistics printed to stdout
#   - Exit code 0 on success
#
# ==============================================================================

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

# Reset endpoint tracking at start of generation run
reset_endpoint_tracking()

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

  # Optional per-API post-processing (e.g. chemi aggregates by file)
  if (!is.null(spec$post)) {
    spec_with_text <- spec$post(spec_with_text)
  }

  if (nrow(spec_with_text) == 0) {
    cli_alert_warning("No {spec$prefix} stubs generated (all skipped)")
    return(list(scaffold = empty_scaffold(), drift = drift))
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

# ==============================================================================
# Main Execution
# ==============================================================================

cli_h1("Function Stub Generation")
cli_alert_info("Working directory: {getwd()}")

api_specs <- list(ct = ct_spec, chemi = chemi_spec)

# Each result is list(scaffold = <tibble>, drift = <tibble>) — uniform shape.
results <- map(api_specs, run_generator)

# Combine scaffold and drift results, tagging each row with its API.
all_results <- imap(results, ~ .x$scaffold %>% mutate(api = .y)) %>% list_rbind()
all_drift <- imap(results, ~ .x$drift %>% mutate(api = .y)) %>% list_rbind()

# Report skipped/suspicious endpoints
report_skipped_endpoints(log_dir = here::here("dev", "logs"))

# ==============================================================================
# Summary
# ==============================================================================

cli_h1("Summary")

# Count actions by type
summary_stats <- all_results %>%
  count(action) %>%
  arrange(desc(n))

if (nrow(all_results) == 0) {
  cli_alert_success("No new function stubs needed - all endpoints are implemented!")
} else {
  # Print summary
  created <- sum(all_results$action == "created", na.rm = TRUE)
  appended <- sum(all_results$action == "appended", na.rm = TRUE)
  skipped <- sum(str_detect(all_results$action, "skipped"), na.rm = TRUE)
  errors <- sum(all_results$action == "error", na.rm = TRUE)

  protected <- sum(all_results$action == "skipped_lifecycle", na.rm = TRUE)

  cli_alert_info("Created: {created} file(s)")
  cli_alert_info("Appended: {appended} file(s)")
  cli_alert_info("Skipped: {skipped} file(s)")
  if (protected > 0) {
    cli_alert_warning("Protected (lifecycle guard): {protected} file(s)")
  }
  if (errors > 0) {
    cli_alert_danger("Errors: {errors} file(s)")
  }

  # List created files
  created_files <- all_results %>%
    filter(action %in% c("created", "appended")) %>%
    pull(path)

  if (length(created_files) > 0) {
    cli_h2("Files Modified")
    for (f in created_files) {
      cli_alert_success("{basename(f)}")
    }
  }
}

# ==============================================================================
# Drift Reporting
# ==============================================================================

if (nrow(all_drift) > 0) {
  cli_h2("Parameter Drift Detected")
  cli_alert_warning(
    "{nrow(all_drift)} parameter drift(s) detected across {length(unique(all_drift$endpoint))} endpoint(s)"
  )

  # Group by endpoint
  for (ep in unique(all_drift$endpoint)) {
    ep_drifts <- all_drift %>% filter(endpoint == ep)
    cli_alert_info("Endpoint: {ep} ({ep_drifts$file[1]})")

    for (i in seq_len(nrow(ep_drifts))) {
      if (ep_drifts$drift_type[i] == "param_added") {
        cli_bullets(c("+" = "Added: {ep_drifts$param_name[i]} ({ep_drifts$schema_value[i]})"))
      } else if (ep_drifts$drift_type[i] == "param_removed") {
        cli_bullets(c("-" = "Removed: {ep_drifts$param_name[i]} (no longer in schema)"))
      }
    }
  }

  # Write drift report to file for CI
  drift_report_path <- here::here("drift_report.csv")
  write.csv(all_drift, drift_report_path, row.names = FALSE)
  cli_alert_info("Drift report written to: {drift_report_path}")
} else {
  cli_alert_success("No parameter drift detected")
}

# Output for GitHub Actions
if (Sys.getenv("GITHUB_OUTPUT") != "") {
  output_file <- Sys.getenv("GITHUB_OUTPUT")

  created <- sum(all_results$action == "created", na.rm = TRUE)
  appended <- sum(all_results$action == "appended", na.rm = TRUE)
  total_new <- created + appended

  drift_count <- nrow(all_drift)
  drift_endpoints <- length(unique(all_drift$endpoint))

  skipped <- sum(str_detect(all_results$action, "skipped"), na.rm = TRUE)
  protected <- sum(all_results$action == "skipped_lifecycle", na.rm = TRUE)

  # Count endpoints that were found but skipped during rendering (empty schemas)
  render_skipped <- sum(vapply(.StubGenEnv$skipped, nrow, integer(1)), na.rm = TRUE)

  cat(sprintf("stubs_generated=%d\n", total_new), file = output_file, append = TRUE)
  cat(sprintf("stubs_created=%d\n", created), file = output_file, append = TRUE)
  cat(sprintf("stubs_appended=%d\n", appended), file = output_file, append = TRUE)
  cat(sprintf("stubs_skipped=%d\n", skipped + render_skipped), file = output_file, append = TRUE)
  cat(sprintf("stubs_protected=%d\n", protected), file = output_file, append = TRUE)
  cat(sprintf("drift_count=%d\n", drift_count), file = output_file, append = TRUE)
  cat(sprintf("drift_endpoints=%d\n", drift_endpoints), file = output_file, append = TRUE)

  cli_alert_info("Output written to GITHUB_OUTPUT")
}

cli_alert_success("Stub generation complete!")
