# ==============================================================================
# Remove Orphan Test Files
# ==============================================================================
#
# This script finds test files in tests/testthat/ that reference functions
# which no longer exist in R/. Useful for cleaning up after stub removal or
# function renaming.
#
# Usage:
#   source("dev/remove_orphan_tests.R")
#
# Configuration:
#   - dry_run:  TRUE (default) to preview, FALSE to delete with confirmation
#   - prefix:   Regex prefix to filter test files (e.g., "ct_", "chemi_", "ct_bioactivity")
#               Set to NULL to scan all test-*.R files
#
# Safety:
#   - Defaults to dry-run mode
#   - Lists orphan files before deletion
#   - Requires interactive confirmation before proceeding
#   - Also detects associated orphan cassettes in tests/testthat/fixtures/
#
# ==============================================================================

library(tidyverse)
library(cli)

# ==============================================================================
# Configuration
# ==============================================================================

dry_run <- FALSE          # Set to FALSE to delete with confirmation
prefix  <- NULL          # Regex prefix filter, e.g. "ct_", "chemi_amos", NULL = all

# ==============================================================================
# Discover exported functions from R/ source files
# ==============================================================================

cli_h1("Orphan Test Removal")

cli_alert_info("Scanning R/ for exported function definitions...")

r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)

# Extract all function assignments: fn_name <- function(...)
exported_functions <- character()

for (file in r_files) {
  content <- readLines(file, warn = FALSE)
  # Match standard assignment: name <- function( or name = function(
  fn_matches <- stringr::str_extract(
    content,
    "^([a-zA-Z_][a-zA-Z0-9_.\\-]*)\\s*(<-|=)\\s*function\\s*\\("
  )
  fn_names <- stringr::str_extract(
    fn_matches[!is.na(fn_matches)],
    "^[a-zA-Z_][a-zA-Z0-9_.\\-]*"
  )
  exported_functions <- c(exported_functions, fn_names)
}

exported_functions <- unique(exported_functions)
cli_alert_success("Found {length(exported_functions)} function(s) defined in R/")

# ==============================================================================
# Scan test files and cross-reference
# ==============================================================================

cli_alert_info("Scanning tests/testthat/ for test files...")

test_files <- list.files(
  "tests/testthat",
  pattern = "^test-.*\\.R$",
  full.names = TRUE
)

# Apply prefix filter
if (!is.null(prefix)) {
  prefix_pattern <- paste0("^test-", prefix)
  test_files <- test_files[grep(prefix_pattern, basename(test_files))]
  cli_alert_info("Prefix filter {.val {prefix}}: {length(test_files)} test file(s) match")
}

# For each test file, derive the function name it tests.
# Convention: test-<function_name>.R  =>  function_name
# Some function names use hyphens (e.g., ct_bioactivity_aop_by-toxcast-aeid)
derive_function_name <- function(test_path) {
  basename(test_path) %>%
    stringr::str_remove("^test-") %>%
    stringr::str_remove("\\.R$")
}

orphan_files <- character()
matched_files <- character()

for (tf in test_files) {
  fn_name <- derive_function_name(tf)

  # Check if function exists (exact match or underscore variant)
  # Some test files use hyphens where the function uses underscores
  fn_name_underscore <- stringr::str_replace_all(fn_name, "-", "_")

  if (fn_name %in% exported_functions ||
      fn_name_underscore %in% exported_functions) {
    matched_files <- c(matched_files, tf)
  } else {
    orphan_files <- c(orphan_files, tf)
  }
}

# ==============================================================================
# Find associated orphan cassettes
# ==============================================================================

cassette_dir <- "tests/testthat/fixtures"
orphan_cassettes <- character()

if (dir.exists(cassette_dir) && length(orphan_files) > 0) {
  all_cassettes <- list.files(cassette_dir, full.names = TRUE)

  for (of in orphan_files) {
    fn_name <- derive_function_name(of)
    # Cassettes are typically named <function_name>_*.yml
    cassette_pattern <- paste0("^", stringr::str_replace_all(fn_name, "([.\\-])", "\\\\\\1"))
    matching <- all_cassettes[grep(cassette_pattern, basename(all_cassettes))]
    orphan_cassettes <- c(orphan_cassettes, matching)
  }

  orphan_cassettes <- unique(orphan_cassettes)
}

# ==============================================================================
# Report findings
# ==============================================================================

cli_h2("Results")

if (length(orphan_files) == 0) {
  cli_alert_success("No orphan test files found. All test files reference existing functions.")
} else {
  cli_alert_warning("Found {length(orphan_files)} orphan test file(s):")
  cat("\n")

  orphan_summary <- tibble(
    file = orphan_files,
    filename = basename(file),
    derived_function = map_chr(file, derive_function_name),
    size_kb = round(file.size(file) / 1024, 2)
  ) %>%
    arrange(filename)

  print(orphan_summary, n = Inf)

  cat("\n")
  cli_alert_info("Total orphan tests: {nrow(orphan_summary)}")
  cli_alert_info("Total size: {round(sum(orphan_summary$size_kb), 2)} KB")

  if (length(orphan_cassettes) > 0) {
    cat("\n")
    cli_alert_warning("Found {length(orphan_cassettes)} associated orphan cassette(s):")

    cassette_summary <- tibble(
      file = orphan_cassettes,
      filename = basename(file),
      size_kb = round(file.size(file) / 1024, 2)
    ) %>%
      arrange(filename)

    print(cassette_summary, n = Inf)

    cat("\n")
    cli_alert_info("Total orphan cassettes: {nrow(cassette_summary)}")
    cli_alert_info("Total cassette size: {round(sum(cassette_summary$size_kb), 2)} KB")
  }

  cat("\n")
  cli_alert_info("Matched (kept): {length(matched_files)} test file(s)")

  # ============================================================================
  # Delete files (with confirmation)
  # ============================================================================

  if (dry_run) {
    cli_h2("Dry Run")
    cli_alert_info("DRY RUN MODE: No files will be deleted.")
    cli_alert("Set {.code dry_run <- FALSE} and re-source to delete.")
  } else {
    all_targets <- c(orphan_files, orphan_cassettes)
    cli_h2("Deletion")
    cat("WARNING: This will permanently delete", length(all_targets), "file(s).\n")
    cat("Type 'yes' to confirm deletion: ")

    response <- readline()

    if (tolower(trimws(response)) == "yes") {
      cat("\nDeleting files...\n")

      deleted_count <- 0
      failed_count <- 0

      for (target in all_targets) {
        result <- tryCatch({
          file.remove(target)
          TRUE
        }, error = function(e) {
          cat("  ERROR:", target, "-", e$message, "\n")
          FALSE
        })

        if (result) {
          cat("  Deleted:", target, "\n")
          deleted_count <- deleted_count + 1
        } else {
          failed_count <- failed_count + 1
        }
      }

      cat("\nDeletion complete:\n")
      cat("  Successfully deleted:", deleted_count, "files\n")
      if (failed_count > 0) {
        cat("  Failed to delete:", failed_count, "files\n")
      }
    } else {
      cat("\nDeletion cancelled.\n")
    }
  }
}

# ==============================================================================
# Cleanup
# ==============================================================================

rm(
  dry_run, prefix,
  r_files, exported_functions,
  test_files, orphan_files, matched_files,
  orphan_cassettes, cassette_dir
)

if (exists("content")) rm(content)
if (exists("fn_matches")) rm(fn_matches)
if (exists("fn_names")) rm(fn_names)
if (exists("fn_name")) rm(fn_name)
if (exists("fn_name_underscore")) rm(fn_name_underscore)
if (exists("tf")) rm(tf)
if (exists("of")) rm(of)
if (exists("file")) rm(file)
if (exists("orphan_summary")) rm(orphan_summary)
if (exists("cassette_summary")) rm(cassette_summary)
if (exists("all_cassettes")) rm(all_cassettes)
if (exists("cassette_pattern")) rm(cassette_pattern)
if (exists("matching")) rm(matching)
if (exists("prefix_pattern")) rm(prefix_pattern)
if (exists("response")) rm(response)
if (exists("deleted_count")) rm(deleted_count)
if (exists("failed_count")) rm(failed_count)
if (exists("result")) rm(result)
if (exists("target")) rm(target)
if (exists("all_targets")) rm(all_targets)
