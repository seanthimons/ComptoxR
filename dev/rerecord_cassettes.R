#!/usr/bin/env Rscript

# ==============================================================================
# VCR Cassette Re-recording Script
# ==============================================================================
#
# PURPOSE:
#   Re-record VCR cassettes from production CompTox APIs after test fixes.
#   Supports batched, parallel execution to handle rate limits efficiently.
#
# REQUIREMENTS:
#   - Valid API key in ctx_api_key environment variable
#   - Required packages: mirai, cli, fs, here, testthat
#
# USAGE:
#   Rscript dev/rerecord_cassettes.R              # Priority batch (default)
#   Rscript dev/rerecord_cassettes.R --all        # All test files
#   Rscript dev/rerecord_cassettes.R --failures   # Re-run failed files only
#   Rscript dev/rerecord_cassettes.R --batch-size 30 --workers 4  # Custom config
#
# ==============================================================================

# Load required packages -------------------------------------------------------
suppressPackageStartupMessages({
  library(cli)
  library(fs)
  library(here)
  library(testthat)
  library(mirai)
})

# Configuration ----------------------------------------------------------------
N_WORKERS <- 8                          # Number of parallel workers
BATCH_SIZE <- 20                        # Files per batch (20-50 range)
BASE_DELAY <- 0.5                       # Seconds between batch submissions
CASSETTE_DIR <- here::here("tests/testthat/fixtures")
TEST_DIR <- here::here("tests/testthat")
LOG_FILE <- here::here("dev/logs/rerecord_failures.log")

# Priority patterns (LOCKED DECISION) -----------------------------------------
PRIORITY_PATTERNS <- c(
  "^test-ct_chemical",
  "^test-chemi_search",
  "^test-chemi_resolver"
)

# Pre-flight checks ------------------------------------------------------------
preflight_checks <- function() {
  cli::cli_h1("Pre-flight Checks")

  # Check API key
  api_key <- Sys.getenv("ctx_api_key")
  if (api_key == "" || nchar(api_key) == 0) {
    cli::cli_abort(c(
      "x" = "No API key found",
      "i" = "Set ctx_api_key environment variable",
      "i" = "Request keys via email to ccte_api@epa.gov"
    ))
  }
  cli::cli_alert_success("API key found")

  # Check mirai
  if (!requireNamespace("mirai", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "mirai package not installed",
      "i" = "Install with: install.packages('mirai')"
    ))
  }
  cli::cli_alert_success("mirai package available")

  # Check test directory
  if (!fs::dir_exists(TEST_DIR)) {
    cli::cli_abort(c(
      "x" = "Test directory not found: {TEST_DIR}"
    ))
  }
  cli::cli_alert_success("Test directory found")

  # Create log directory if needed
  log_dir <- fs::path_dir(LOG_FILE)
  if (!fs::dir_exists(log_dir)) {
    fs::dir_create(log_dir, recurse = TRUE)
    cli::cli_alert_info("Created log directory: {log_dir}")
  }

  cli::cli_alert_success("Pre-flight checks complete")
  invisible(TRUE)
}

# Get test files based on mode ------------------------------------------------
get_test_files <- function(mode = "priority") {
  if (mode == "failures") {
    # Read from log file
    if (!fs::file_exists(LOG_FILE)) {
      cli::cli_abort(c(
        "x" = "No failures log found: {LOG_FILE}",
        "i" = "Run with default or --all mode first"
      ))
    }
    files <- readLines(LOG_FILE)
    files <- files[nchar(files) > 0]  # Remove empty lines
    return(files)

  } else if (mode == "all") {
    # All test files
    files <- fs::dir_ls(TEST_DIR, regexp = "^test-.*\\.R$")
    return(as.character(files))

  } else if (mode == "priority") {
    # Priority patterns only
    all_files <- fs::dir_ls(TEST_DIR, regexp = "^test-.*\\.R$")
    pattern <- paste(PRIORITY_PATTERNS, collapse = "|")
    files <- all_files[grepl(pattern, fs::path_file(all_files))]
    return(as.character(files))

  } else {
    cli::cli_abort("Unknown mode: {mode}")
  }
}

# Delete existing cassettes for test file -------------------------------------
delete_cassettes <- function(test_file) {
  # Extract test file basename without extension
  test_name <- fs::path_ext_remove(fs::path_file(test_file))
  test_name <- sub("^test-", "", test_name)

  # Find matching cassettes
  pattern <- paste0("^", test_name)
  cassettes <- fs::dir_ls(CASSETTE_DIR, regexp = pattern)

  if (length(cassettes) > 0) {
    fs::file_delete(cassettes)
    return(length(cassettes))
  }
  return(0)
}

# Re-record cassettes in batches ----------------------------------------------
rerecord_batch <- function(test_files, n_workers = N_WORKERS,
                           batch_size = BATCH_SIZE, base_delay = BASE_DELAY) {

  # Split into batches
  n_files <- length(test_files)
  n_batches <- ceiling(n_files / batch_size)

  cli::cli_h2("Processing {n_files} files in {n_batches} batch{?es}")

  all_failures <- character(0)
  all_successes <- character(0)

  for (batch_idx in seq_len(n_batches)) {
    start_idx <- (batch_idx - 1) * batch_size + 1
    end_idx <- min(batch_idx * batch_size, n_files)
    batch_files <- test_files[start_idx:end_idx]

    cli::cli_h3("Batch {batch_idx}/{n_batches}: Processing {length(batch_files)} files")

    # Delete existing cassettes first
    cli::cli_alert_info("Deleting existing cassettes...")
    deleted_counts <- sapply(batch_files, delete_cassettes)
    total_deleted <- sum(deleted_counts)
    cli::cli_alert_success("Deleted {total_deleted} cassette{?s}")

    # Initialize mirai daemons
    mirai::daemons(n = n_workers)

    # Submit mirai tasks
    cli::cli_alert_info("Submitting {length(batch_files)} test{?s} to worker pool...")
    tasks <- list()

    for (i in seq_along(batch_files)) {
      file <- batch_files[i]

      # Submit async task with error handling
      tasks[[i]] <- mirai::mirai({
        result <- tryCatch({
          # Run test file (will trigger VCR recording)
          testthat::test_file(file, reporter = "minimal")
          list(file = file, success = TRUE, error = NULL)
        }, error = function(e) {
          list(file = file, success = FALSE, error = as.character(e$message))
        })
        result
      }, file = file)
    }

    # Collect results
    cli::cli_alert_info("Waiting for results...")
    cli::cli_progress_bar("Recording cassettes", total = length(tasks))

    batch_failures <- character(0)
    batch_successes <- character(0)

    for (i in seq_along(tasks)) {
      result <- mirai::call_mirai(tasks[[i]])$.data

      if (result$success) {
        batch_successes <- c(batch_successes, result$file)
      } else {
        batch_failures <- c(batch_failures, result$file)
        cli::cli_alert_warning("Failed: {fs::path_file(result$file)}")
        if (!is.null(result$error)) {
          cli::cli_alert_danger("  Error: {result$error}")
        }
      }

      cli::cli_progress_update()
    }
    cli::cli_progress_done()

    # Clean up daemons
    mirai::daemons(0)

    # Update cumulative results
    all_failures <- c(all_failures, batch_failures)
    all_successes <- c(all_successes, batch_successes)

    # Batch summary
    cli::cli_alert_success("Batch {batch_idx} complete: {length(batch_successes)} success, {length(batch_failures)} failure{?s}")

    # Delay between batches (except last)
    if (batch_idx < n_batches) {
      cli::cli_alert_info("Waiting {base_delay}s before next batch...")
      Sys.sleep(base_delay)
    }
  }

  return(list(
    successes = all_successes,
    failures = all_failures
  ))
}

# Parse command-line arguments ------------------------------------------------
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  mode <- "priority"
  n_workers <- N_WORKERS
  batch_size <- BATCH_SIZE

  i <- 1
  while (i <= length(args)) {
    arg <- args[i]

    if (arg == "--all") {
      mode <- "all"

    } else if (arg == "--failures") {
      mode <- "failures"

    } else if (arg == "--batch-size") {
      if (i == length(args)) {
        cli::cli_abort("--batch-size requires a value")
      }
      batch_size <- as.integer(args[i + 1])
      i <- i + 1

    } else if (arg == "--workers") {
      if (i == length(args)) {
        cli::cli_abort("--workers requires a value")
      }
      n_workers <- as.integer(args[i + 1])
      i <- i + 1

    } else {
      cli::cli_abort("Unknown argument: {arg}")
    }

    i <- i + 1
  }

  list(mode = mode, n_workers = n_workers, batch_size = batch_size)
}

# Main execution ---------------------------------------------------------------
main <- function() {
  cli::cli_h1("VCR Cassette Re-recording")

  # Parse arguments
  config <- parse_args()

  # Pre-flight checks
  preflight_checks()

  # Get test files
  test_files <- get_test_files(config$mode)

  if (length(test_files) == 0) {
    cli::cli_alert_warning("No test files found for mode: {config$mode}")
    return(invisible(NULL))
  }

  # Show configuration
  cli::cli_alert_info("Mode: {config$mode}")
  cli::cli_alert_info("Workers: {config$n_workers}")
  cli::cli_alert_info("Batch size: {config$batch_size}")
  cli::cli_alert_info("Test files: {length(test_files)}")

  # Start timer
  start_time <- Sys.time()

  # Re-record cassettes
  results <- rerecord_batch(
    test_files,
    n_workers = config$n_workers,
    batch_size = config$batch_size
  )

  # Calculate elapsed time
  elapsed_time <- difftime(Sys.time(), start_time, units = "mins")

  # Write failures to log (overwrite)
  if (length(results$failures) > 0) {
    writeLines(results$failures, LOG_FILE)
    cli::cli_alert_warning("Logged {length(results$failures)} failure{?s} to: {LOG_FILE}")
  } else {
    # Clear log file if no failures
    if (fs::file_exists(LOG_FILE)) {
      fs::file_delete(LOG_FILE)
    }
  }

  # Final summary
  cli::cli_h1("Summary")
  cli::cli_alert_success("Successes: {length(results$successes)}")
  cli::cli_alert_warning("Failures: {length(results$failures)}")
  cli::cli_alert_info("Time elapsed: {round(elapsed_time, 2)} minutes")

  # Re-run suggestion
  if (length(results$failures) > 0) {
    cli::cli_alert_info("Re-run failures with: Rscript dev/rerecord_cassettes.R --failures")
  }

  invisible(results)
}

# Run if called as script -----------------------------------------------------
if (!interactive()) {
  main()
}
