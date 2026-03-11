#!/usr/bin/env Rscript
# Calculate API schema coverage for CCD and Cheminformatic services
#
# Uses the same shared utilities (select_schema_files, openapi_to_spec,
# ENDPOINT_PATTERNS_TO_EXCLUDE) as the diff engine and stub generator
# to ensure consistent endpoint counting across all three systems.

suppressPackageStartupMessages({
  library(jsonlite)
  library(here)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(cli)
})

# Load shared utilities
source(here::here("dev/endpoint_eval/00_config.R"))
source(here::here("dev/endpoint_eval/01_schema_resolution.R"))
source(here::here("dev/endpoint_eval/06_param_parsing.R"))
source(here::here("dev/endpoint_eval/04_openapi_parser.R"))

# ==============================================================================
# Endpoint counting (from schemas, using shared parser)
# ==============================================================================

#' Count endpoints across schema files using openapi_to_spec
#'
#' @param schema_files Character vector of schema filenames (not full paths)
#' @param exclude_pattern Regex to exclude from endpoint routes
#' @return Integer count of unique endpoints
count_endpoints_from_schemas <- function(schema_files, exclude_pattern = ENDPOINT_PATTERNS_TO_EXCLUDE) {
  if (length(schema_files) == 0) return(0L)

  endpoints <- tryCatch({
    map(schema_files, ~ {
      openapi <- jsonlite::fromJSON(here::here("schema", .x), simplifyVector = FALSE)
      suppressMessages(openapi_to_spec(openapi))
    }) %>%
      list_rbind() %>%
      filter(
        str_detect(method, "GET|POST"),
        !str_detect(route, exclude_pattern)
      ) %>%
      distinct(route, method)
  }, error = function(e) {
    cli_alert_warning("Error parsing schemas: {e$message}")
    tibble()
  })

  nrow(endpoints)
}

# ==============================================================================
# Function counting (from R files)
# ==============================================================================

count_r_functions <- function(function_prefix) {
  r_files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
  function_count <- 0L

  for (r_file in r_files) {
    lines <- readLines(r_file, warn = FALSE)
    pattern <- sprintf("^%s[a-zA-Z0-9_]* ?(<-|=) ?function\\(", function_prefix)
    matches <- grep(pattern, lines, value = FALSE)
    function_count <- function_count + length(matches)
  }

  function_count
}

# ==============================================================================
# CCD Coverage
# ==============================================================================

cat("Calculating CCD (CompTox Chemical Dashboard) coverage...\n")

ccd_schema_files <- list.files(
  here::here("schema"),
  pattern = "^ctx-.*-prod\\.json$",
  full.names = FALSE
)

ccd_endpoints <- count_endpoints_from_schemas(ccd_schema_files)
ccd_functions <- count_r_functions("ct_")
ccd_coverage_raw <- if (ccd_endpoints > 0) (ccd_functions / ccd_endpoints) * 100 else 0
ccd_coverage <- min(round(ccd_coverage_raw, 1), 100.0)

cat(sprintf("CCD Endpoints: %d\n", ccd_endpoints))
cat(sprintf("CCD Functions: %d\n", ccd_functions))
cat(sprintf("CCD Coverage: %.1f%%\n\n", ccd_coverage))

# ==============================================================================
# Cheminformatic Coverage
# ==============================================================================

cat("Calculating Cheminformatic coverage...\n")

# Use select_schema_files with stage priority — same as stub generator
chemi_schema_files <- select_schema_files(
  pattern = "^chemi-.*\\.json$",
  exclude_pattern = "ui|coverage_baseline|schema_hashes",
  stage_priority = c("prod", "staging", "dev")
)

chemi_endpoints <- count_endpoints_from_schemas(chemi_schema_files)
chemi_functions <- count_r_functions("chemi_")
chemi_coverage_raw <- if (chemi_endpoints > 0) (chemi_functions / chemi_endpoints) * 100 else 0
chemi_coverage <- min(round(chemi_coverage_raw, 1), 100.0)

cat(sprintf("Cheminformatic Endpoints: %d\n", chemi_endpoints))
cat(sprintf("Cheminformatic Functions: %d\n", chemi_functions))
cat(sprintf("Cheminformatic Coverage: %.1f%%\n\n", chemi_coverage))

# ==============================================================================
# Badge colors
# ==============================================================================

get_badge_color <- function(coverage) {
  if (coverage >= 80) "brightgreen"
  else if (coverage >= 60) "green"
  else if (coverage >= 40) "yellow"
  else if (coverage >= 20) "orange"
  else "red"
}

ccd_color <- get_badge_color(ccd_coverage)
chemi_color <- get_badge_color(chemi_coverage)

# ==============================================================================
# Coverage deltas (vs baseline)
# ==============================================================================

baseline_path <- here::here("schema", "coverage_baseline.json")
baseline <- if (file.exists(baseline_path)) {
  tryCatch(jsonlite::fromJSON(baseline_path), error = function(e) {
    warning(sprintf("Error reading baseline: %s", e$message))
    NULL
  })
} else {
  NULL
}

format_delta <- function(current, baseline_val) {
  if (is.null(baseline_val) || is.na(baseline_val)) return("")
  diff <- current - baseline_val
  if (abs(diff) < 1e-9) return("")
  is_whole <- abs(current - round(current)) < 1e-9
  if (is_whole) sprintf(" (%+d)", as.integer(round(diff)))
  else sprintf(" (%+.1f)", diff)
}

ccd_coverage_fmt <- paste0(sprintf("%.1f%%", ccd_coverage), format_delta(ccd_coverage, baseline$ccd_coverage))
ccd_endpoints_fmt <- paste0(ccd_endpoints, format_delta(ccd_endpoints, baseline$ccd_endpoints))
ccd_functions_fmt <- paste0(ccd_functions, format_delta(ccd_functions, baseline$ccd_functions))
chemi_coverage_fmt <- paste0(sprintf("%.1f%%", chemi_coverage), format_delta(chemi_coverage, baseline$chemi_coverage))
chemi_endpoints_fmt <- paste0(chemi_endpoints, format_delta(chemi_endpoints, baseline$chemi_endpoints))
chemi_functions_fmt <- paste0(chemi_functions, format_delta(chemi_functions, baseline$chemi_functions))

cat("\nCoverage deltas (vs baseline):\n")
cat(sprintf("  CCD:   %s | %s endpoints | %s functions\n", ccd_coverage_fmt, ccd_endpoints_fmt, ccd_functions_fmt))
cat(sprintf("  Chemi: %s | %s endpoints | %s functions\n", chemi_coverage_fmt, chemi_endpoints_fmt, chemi_functions_fmt))

# Write updated baseline
new_baseline <- list(
  ccd_coverage = ccd_coverage,
  ccd_endpoints = ccd_endpoints,
  ccd_functions = ccd_functions,
  chemi_coverage = chemi_coverage,
  chemi_endpoints = chemi_endpoints,
  chemi_functions = chemi_functions,
  timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
)
jsonlite::write_json(new_baseline, baseline_path, auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("Baseline updated: %s\n", baseline_path))

# ==============================================================================
# GitHub Actions output
# ==============================================================================

if (Sys.getenv("GITHUB_OUTPUT") != "") {
  output_file <- Sys.getenv("GITHUB_OUTPUT")
  cat(sprintf("ccd_coverage=%.1f\n", ccd_coverage), file = output_file, append = TRUE)
  cat(sprintf("ccd_color=%s\n", ccd_color), file = output_file, append = TRUE)
  cat(sprintf("chemi_coverage=%.1f\n", chemi_coverage), file = output_file, append = TRUE)
  cat(sprintf("chemi_color=%s\n", chemi_color), file = output_file, append = TRUE)
  cat(sprintf("ccd_endpoints=%d\n", ccd_endpoints), file = output_file, append = TRUE)
  cat(sprintf("ccd_functions=%d\n", ccd_functions), file = output_file, append = TRUE)
  cat(sprintf("chemi_endpoints=%d\n", chemi_endpoints), file = output_file, append = TRUE)
  cat(sprintf("chemi_functions=%d\n", chemi_functions), file = output_file, append = TRUE)

  cat(sprintf("ccd_coverage_fmt=%s\n", ccd_coverage_fmt), file = output_file, append = TRUE)
  cat(sprintf("ccd_endpoints_fmt=%s\n", ccd_endpoints_fmt), file = output_file, append = TRUE)
  cat(sprintf("ccd_functions_fmt=%s\n", ccd_functions_fmt), file = output_file, append = TRUE)
  cat(sprintf("chemi_coverage_fmt=%s\n", chemi_coverage_fmt), file = output_file, append = TRUE)
  cat(sprintf("chemi_endpoints_fmt=%s\n", chemi_endpoints_fmt), file = output_file, append = TRUE)
  cat(sprintf("chemi_functions_fmt=%s\n", chemi_functions_fmt), file = output_file, append = TRUE)

  cat("Coverage data written to GITHUB_OUTPUT\n")
}

cat("\n=== Summary ===\n")
cat(sprintf("CCD Coverage: %.1f%% (%d/%d) - Color: %s\n",
            ccd_coverage, ccd_functions, ccd_endpoints, ccd_color))
cat(sprintf("Cheminformatic Coverage: %.1f%% (%d/%d) - Color: %s\n",
            chemi_coverage, chemi_functions, chemi_endpoints, chemi_color))
