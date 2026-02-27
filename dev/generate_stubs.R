#!/usr/bin/env Rscript
# ==============================================================================
# Automated Function Stub Generation for CI
# ==============================================================================
#
# This script generates R function stubs from OpenAPI schemas for all APIs:
#   - CompTox Dashboard (ct_*)
#   - Cheminformatics (chemi_*)
#   - Common Chemistry (cc_*)
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

# Common Chemistry (cc_*) function generation configuration
cc_config <- list(
  wrapper_function = "generic_cc_request",
  param_strategy = "extra_params",
  example_query = "123-91-1",
  lifecycle_badge = "experimental",
  batch_limit = 1
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
# Helper Functions
# ==============================================================================
# Note: select_schema_files() has been moved to dev/endpoint_eval/01_schema_resolution.R
# for shared use between generate_stubs.R and diff_schemas.R

#' Generate stubs for CompTox Dashboard API
#' @return tibble with scaffold results
generate_ct_stubs <- function() {
  cli_h2("CompTox Dashboard (ct_*)")

  ctx_schema_files <- list.files(
    path = here::here('schema'),
    pattern = "^ctx-.*-prod\\.json$",
    full.names = FALSE
  )

  if (length(ctx_schema_files) == 0) {
    cli_alert_warning("No ctx schema files found, skipping ct_* generation")
    return(tibble(action = character(), file = character()))
  }

  cli_alert_info("Found {length(ctx_schema_files)} ctx schema file(s)")

  # Parse all schemas
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
      file = route %>%
        str_remove_all(regex("(?i)(?:^|[/_-])(?:hazards?|chemical?|exposures?|bioactivit(?:y|ies)|search(?:es)?|summary|by[/_-]dtxsid)(?=$|[/_-])")) %>%
        str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>%
        str_replace_all("[/]+", " ") %>%
        str_squish() %>%
        str_replace_all("\\s", "_"),
      file = paste0("ct_", domain, "_", file, ".R"),
      batch_limit = case_when(
        method == 'GET' & !is.na(num_path_params) & num_path_params > 0 ~ 1,
        method == 'GET' & !is.na(num_path_params) & num_path_params == 0 ~ 0,
        .default = NULL
      )
    ) %>%
    arrange(forcats::fct_inorder(domain), route, factor(method, levels = c('POST', 'GET'))) %>%
    distinct(route, .keep_all = TRUE)

  cli_alert_info("Parsed {nrow(endpoints)} endpoint(s) from schemas")

  # Find missing endpoints
  res <- find_endpoint_usages_base(
    endpoints$route,
    pkg_dir = here::here("R"),
    files_regex = "^ct_.*\\.R$",
    expected_files = endpoints$file
  )

  # Detect parameter drift for existing endpoints
  ct_drift <- detect_parameter_drift(
    endpoints = endpoints,
    usage_summary = res$summary %>% filter(n_hits > 0),
    pkg_dir = here::here("R")
  )

  endpoints_to_build <- endpoints %>%
    filter(route %in% {res$summary %>% filter(n_hits == 0) %>% pull(endpoint)})

  if (nrow(endpoints_to_build) == 0) {
    cli_alert_success("All ct_* endpoints already implemented")
    # Return drift results even if no new stubs
    return(list(
      scaffold = tibble(action = character(), file = character()),
      drift = ct_drift
    ))
  }

  cli_alert_info("Found {nrow(endpoints_to_build)} endpoint(s) to generate")

  # Generate stubs
  spec_with_text <- render_endpoint_stubs(endpoints_to_build, config = ct_config)

  # Write files
  scaffold_result <- scaffold_files(spec_with_text, base_dir = "R", overwrite = FALSE, append = TRUE, quiet = TRUE)

  # Return both scaffold and drift results
  list(
    scaffold = scaffold_result,
    drift = ct_drift
  )
}

#' Generate stubs for Cheminformatics API
#' @return tibble with scaffold results
generate_chemi_stubs <- function() {
  cli_h2("Cheminformatics (chemi_*)")

  # Select schema files with stage prioritization
  chemi_schema_files <- select_schema_files(
    pattern = "^chemi-.*\\.json$",
    exclude_pattern = "ui",
    stage_priority = c("prod", "staging", "dev")
  )

  if (length(chemi_schema_files) == 0) {
    cli_alert_warning("No chemi schema files found, skipping chemi_* generation")
    return(tibble(action = character(), file = character()))
  }

  cli_alert_info("Found {length(chemi_schema_files)} chemi schema file(s)")

  # Parse all schemas using openapi_to_spec directly
  # UNIFIED PIPELINE (v1.6 - UNIFY-CHEMI decision):
  # Previously used parse_chemi_schemas() which was chemi-specific.
  # Now calls openapi_to_spec() directly, same as generate_ct_stubs() and generate_cc_stubs().
  # This ensures consistent Swagger 2.0 handling across all generators.
  chemi_endpoints <- tryCatch({
    map(
      chemi_schema_files,
      ~ {
        openapi <- jsonlite::fromJSON(here::here('schema', .x), simplifyVector = FALSE)
        # openapi_to_spec handles both Swagger 2.0 (amos, rdkit, mordred) and OpenAPI 3.0
        spec <- openapi_to_spec(openapi)
        spec$source_file <- .x
        spec
      },
      .progress = FALSE
    ) %>%
      list_rbind() %>%
      filter(
        str_detect(method, 'GET|POST'),
        !str_detect(route, ENDPOINT_PATTERNS_TO_EXCLUDE)  # Exclude admin/UI routes
      ) %>%
      mutate(
        route = strip_curly_params(route, leading_slash = 'remove'),
        domain = route %>% str_extract("^api/([^/]+)") %>% str_remove("^api/"),
        name = route %>%
          str_remove_all("^api/") %>%
          str_remove_all(regex("(?i)(?:^|[/_-])(?:chemi|search(?:es)?|summary|by[/_-]dtxsid)(?=$|[/_-])")) %>%
          str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>%
          str_replace_all("[/]+", " ") %>%
          str_squish() %>%
          str_replace_all("\\s", "_") %>%
          str_replace_all("-", "_"),
        file = case_when(
          nchar(name) == 0 ~ paste0("chemi_", domain, ".R"),
          str_detect(name, pattern = domain) ~ paste0("chemi_", name, ".R"),
          .default = paste0("chemi_", domain, "_", name, ".R")
        ),
        batch_limit = 0,
        route = str_remove_all(route, "^api/")
      ) %>%
      group_by(file) %>%
      mutate(
        method_count = n(),
        fn = case_when(
          method_count == 1 ~ tools::file_path_sans_ext(basename(file)),
          method == "GET" ~ tools::file_path_sans_ext(basename(file)),
          method == "POST" ~ paste0(tools::file_path_sans_ext(basename(file)), "_bulk"),
          .default = paste0(tools::file_path_sans_ext(basename(file)), "_", tolower(method))
        )
      ) %>%
      ungroup() %>%
      select(-method_count)
  }, error = function(e) {
    cli_alert_warning("Error parsing chemi schemas: {e$message}")
    return(tibble())
  })

  if (nrow(chemi_endpoints) == 0) {
    cli_alert_warning("No chemi endpoints parsed")
    return(tibble(action = character(), file = character()))
  }

  cli_alert_info("Parsed {nrow(chemi_endpoints)} endpoint(s) from schemas")

  # Find missing endpoints
  res_chemi <- find_endpoint_usages_base(
    chemi_endpoints$route,
    pkg_dir = here::here("R"),
    files_regex = "^chemi_.*\\.R$",
    expected_files = chemi_endpoints$file
  )

  # Detect parameter drift for existing endpoints
  chemi_drift <- detect_parameter_drift(
    endpoints = chemi_endpoints,
    usage_summary = res_chemi$summary %>% filter(n_hits > 0),
    pkg_dir = here::here("R")
  )

  chemi_endpoints_to_build <- chemi_endpoints %>%
    filter(route %in% {res_chemi$summary %>% filter(n_hits == 0) %>% pull(endpoint)})

  if (nrow(chemi_endpoints_to_build) == 0) {
    cli_alert_success("All chemi_* endpoints already implemented")
    # Return drift results even if no new stubs
    return(list(
      scaffold = tibble(action = character(), file = character()),
      drift = chemi_drift
    ))
  }

  cli_alert_info("Found {nrow(chemi_endpoints_to_build)} endpoint(s) to generate")

  # Generate stubs
  chemi_spec_with_text <- render_endpoint_stubs(chemi_endpoints_to_build, config = chemi_config)

  # Check if any stubs were generated (render may skip endpoints with empty schemas)
  if (nrow(chemi_spec_with_text) == 0) {
    cli_alert_warning("No chemi stubs generated (all skipped)")
    # Return drift results even if no stubs
    return(list(
      scaffold = tibble(action = character(), file = character()),
      drift = chemi_drift
    ))
  }

  # Aggregate by file (multiple functions per file)
  chemi_spec_aggregated <- chemi_spec_with_text %>%
    group_by(file) %>%
    summarise(text = paste(text, collapse = "\n\n"), .groups = "drop")

  # Write files
  scaffold_result <- scaffold_files(chemi_spec_aggregated, base_dir = "R", overwrite = FALSE, append = TRUE, quiet = TRUE)

  # Return both scaffold and drift results
  list(
    scaffold = scaffold_result,
    drift = chemi_drift
  )
}

#' Generate stubs for Common Chemistry API
#' @return tibble with scaffold results
generate_cc_stubs <- function() {
  cli_h2("Common Chemistry (cc_*)")

  cc_schema_files <- list.files(
    path = here::here('schema'),
    pattern = "^commonchemistry-prod\\.json$",
    full.names = FALSE
  )

  if (length(cc_schema_files) == 0) {
    cli_alert_warning("No Common Chemistry schema file found, skipping cc_* generation")
    return(tibble(action = character(), file = character()))
  }

  cli_alert_info("Found {length(cc_schema_files)} cc schema file(s)")

  # Parse schemas
  endpoints <- map(
    cc_schema_files,
    ~ {
      openapi <- jsonlite::fromJSON(here::here('schema', .x), simplifyVector = FALSE)
      openapi_to_spec(openapi)
    },
    .progress = FALSE
  ) %>%
    list_rbind() %>%
    mutate(
      route = strip_curly_params(route, leading_slash = 'remove'),
      file = route %>%
        str_replace_all("[/]+", " ") %>%
        str_squish() %>%
        str_replace_all("\\s", "_"),
      file = paste0("cc_", file, ".R"),
      batch_limit = case_when(
        method == 'GET' & !is.na(num_path_params) & num_path_params > 0 ~ 1,
        method == 'GET' & !is.na(num_path_params) & num_path_params == 0 ~ 0,
        .default = NULL
      )
    ) %>%
    distinct(route, .keep_all = TRUE)

  cli_alert_info("Parsed {nrow(endpoints)} endpoint(s) from schemas")

  # Find missing endpoints
  cc_res <- find_endpoint_usages_base(
    endpoints$route,
    pkg_dir = here::here("R"),
    files_regex = "^cc_.*\\.R$",
    expected_files = endpoints$file
  )

  # Detect parameter drift for existing endpoints
  cc_drift <- detect_parameter_drift(
    endpoints = endpoints,
    usage_summary = cc_res$summary %>% filter(n_hits > 0),
    pkg_dir = here::here("R")
  )

  endpoints_to_build <- endpoints %>%
    filter(route %in% {cc_res$summary %>% filter(n_hits == 0) %>% pull(endpoint)})

  if (nrow(endpoints_to_build) == 0) {
    cli_alert_success("All cc_* endpoints already implemented")
    # Return drift results even if no new stubs
    return(list(
      scaffold = tibble(action = character(), file = character()),
      drift = cc_drift
    ))
  }

  cli_alert_info("Found {nrow(endpoints_to_build)} endpoint(s) to generate")

  # Generate stubs
  spec_with_text <- render_endpoint_stubs(endpoints_to_build, config = cc_config)

  # Write files
  scaffold_result <- scaffold_files(spec_with_text, base_dir = "R", overwrite = FALSE, append = TRUE, quiet = TRUE)

  # Return both scaffold and drift results
  list(
    scaffold = scaffold_result,
    drift = cc_drift
  )
}

# ==============================================================================
# Main Execution
# ==============================================================================

cli_h1("Function Stub Generation")
cli_alert_info("Working directory: {getwd()}")

# Generate stubs for all APIs
ct_results <- generate_ct_stubs()
chemi_results <- generate_chemi_stubs()
cc_results <- generate_cc_stubs()

# Extract scaffold and drift results
ct_scaffold <- if (is.list(ct_results) && "scaffold" %in% names(ct_results)) ct_results$scaffold else ct_results
chemi_scaffold <- if (is.list(chemi_results) && "scaffold" %in% names(chemi_results)) chemi_results$scaffold else chemi_results
cc_scaffold <- if (is.list(cc_results) && "scaffold" %in% names(cc_results)) cc_results$scaffold else cc_results

ct_drift <- if (is.list(ct_results) && "drift" %in% names(ct_results)) ct_results$drift else tibble()
chemi_drift <- if (is.list(chemi_results) && "drift" %in% names(chemi_results)) chemi_results$drift else tibble()
cc_drift <- if (is.list(cc_results) && "drift" %in% names(cc_results)) cc_results$drift else tibble()

# Combine scaffold results
all_results <- bind_rows(
  ct_scaffold %>% mutate(api = "ct"),
  chemi_scaffold %>% mutate(api = "chemi"),
  cc_scaffold %>% mutate(api = "cc")
)

# Combine drift results
all_drift <- bind_rows(
  ct_drift %>% mutate(api = "ct"),
  chemi_drift %>% mutate(api = "chemi"),
  cc_drift %>% mutate(api = "cc")
)

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
  cli_alert_warning("{nrow(all_drift)} parameter drift(s) detected across {length(unique(all_drift$endpoint))} endpoint(s)")

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

  cat(sprintf("stubs_generated=%d\n", total_new), file = output_file, append = TRUE)
  cat(sprintf("stubs_created=%d\n", created), file = output_file, append = TRUE)
  cat(sprintf("stubs_appended=%d\n", appended), file = output_file, append = TRUE)
  cat(sprintf("drift_count=%d\n", drift_count), file = output_file, append = TRUE)
  cat(sprintf("drift_endpoints=%d\n", drift_endpoints), file = output_file, append = TRUE)

  cli_alert_info("Output written to GITHUB_OUTPUT")
}

cli_alert_success("Stub generation complete!")
