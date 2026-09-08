# Client policy is prepared once; the installed engine performs comparisons.
source(here::here('dev/toolkit_adapter.R'))
.diff_tools <- comptox_tools(here::here())
wrapmaint::bind_tools('diff', .diff_tools)
list2env(
  mget(
    c('classify_param_change', 'diff_single_schema', 'diff_schemas', 'format_diff_markdown', 'count_diff_changes'),
    envir = .diff_tools
  ),
  envir = environment()
)
# ==============================================================================
# Schema Diffing Engine
# ==============================================================================
# Purpose: Compare two versions of OpenAPI schemas at the endpoint level
# Output: Structured diff report with breaking/non-breaking classification
# Usage: Called by CI workflow to detect API changes between schema versions

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(purrr)
  library(tibble)
  library(here)
})

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

#' Classify parameter changes as breaking or non-breaking
#'
#' @param old_params Comma-separated string of old parameter names
#' @param new_params Comma-separated string of new parameter names
#' @return List with breaking (logical) and detail (string)

# ------------------------------------------------------------------------------
# Single Schema Diff
# ------------------------------------------------------------------------------

#' Compare two versions of a single schema file
#'
#' @param old_path Path to old schema JSON file
#' @param new_path Path to new schema JSON file
#' @return List with schema_file, added (tibble), removed (tibble), modified (tibble)

# ------------------------------------------------------------------------------
# Multi-Schema Diff
# ------------------------------------------------------------------------------

#' Compare all schemas between two directories
#'
#' @param old_dir Directory containing old schema JSON files
#' @param new_dir Directory containing new schema JSON files
#' @param pattern File pattern to match (default: "\\.json$")
#' @param stage_priority Optional character vector of stage names in priority order.
#'   When provided, uses select_schema_files() to filter to canonical schemas per domain.
#'   NULL to diff all matching files (default).
#' @param exclude_pattern Optional pattern to exclude (e.g., "ui"). Only used if stage_priority is provided.
#' @return List of per-schema diff results

# ------------------------------------------------------------------------------
# Markdown Formatting
# ------------------------------------------------------------------------------

#' Format diff results as markdown for PR body injection
#'
#' @param diff_results Output from diff_schemas()
#' @return Markdown string

# ------------------------------------------------------------------------------
# Change Counting
# ------------------------------------------------------------------------------

#' Count breaking / non-breaking endpoint changes from diff_schemas() output
#'
#' Robust to an empty result list (no changes) and to parse-error entries
#' (which carry only `schema_file` + `error`). A plain accumulator loop avoids
#' the `sum(sapply(...))` hazard where sapply over an empty or mixed-length list
#' returns a list and `sum()` aborts with "invalid 'type' (list) of argument".
#'
#' @param diff_results Output from diff_schemas()
#' @return List with breaking (integer) and nonbreaking (integer)

# ------------------------------------------------------------------------------
# CLI Entrypoint (when sourced from CI)
# ------------------------------------------------------------------------------

if (sys.nframe() == 0) {
  # Parse command-line arguments
  args <- commandArgs(trailingOnly = TRUE)
  old_dir <- if (length(args) >= 1) args[1] else "schema_old"
  new_dir <- if (length(args) >= 2) args[2] else "schema"

  # Run diff
  cat("Diffing schemas...\n")
  cat(sprintf("Old: %s\n", old_dir))
  cat(sprintf("New: %s\n", new_dir))

  results <- diff_schemas(old_dir, new_dir)

  # Generate markdown report
  markdown <- format_diff_markdown(results)

  # Write to file
  writeLines(markdown, "schema_diff_report.md")
  cat("Report written to: schema_diff_report.md\n")

  # Calculate counts for CI
  counts <- count_diff_changes(results)

  # Output counts for CI parsing
  cat(sprintf("BREAKING_COUNT=%d\n", counts$breaking))
  cat(sprintf("NONBREAKING_COUNT=%d\n", counts$nonbreaking))
}
