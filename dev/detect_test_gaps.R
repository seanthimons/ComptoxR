#!/usr/bin/env Rscript
# Test Gap Detection - Identify API wrapper functions without proper tests
#
# This script scans R/ for API wrapper functions (ct_*, chemi_*, cc_*) that call
# generic_request/generic_chemi_request/generic_cc_request and identifies which ones:
# - Have no test file at all (no_test_file)
# - Have an empty test file with no test_that() blocks (empty_test_file)
#
# Output:
# - JSON report to dev/reports/test_gaps_{YYYYMMDD}.json
# - GITHUB_OUTPUT variables (gaps_found, gaps_count) when in CI
# - CLI summary to stdout

library(cli)
library(fs)
library(jsonlite)
library(here)

#' Read test manifest
#'
#' @description
#' Reads dev/test_manifest.json and returns the manifest structure.
#' If the file doesn't exist, returns default structure.
#'
#' @return List with version, updated, and files fields
#' @export
read_test_manifest <- function() {
  manifest_path <- here::here("dev", "test_manifest.json")

  if (!file.exists(manifest_path)) {
    return(list(
      version = "1.0",
      updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      files = list()
    ))
  }

  tryCatch({
    jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
  }, error = function(e) {
    cli::cli_alert_warning("Error reading manifest: {e$message}, using default")
    list(
      version = "1.0",
      updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      files = list()
    )
  })
}

#' Write test manifest
#'
#' @description
#' Writes the manifest structure to dev/test_manifest.json
#'
#' @param manifest List with version, updated, and files fields
#' @export
write_test_manifest <- function(manifest) {
  manifest_path <- here::here("dev", "test_manifest.json")
  manifest$updated <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  jsonlite::write_json(
    manifest,
    manifest_path,
    pretty = TRUE,
    auto_unbox = TRUE
  )

  cli::cli_alert_success("Manifest updated: {manifest_path}")
  invisible(manifest_path)
}

#' Check if test file is protected
#'
#' @description
#' Checks if a test file has status "protected" in the manifest
#'
#' @param test_filename Test filename (e.g., "test-ct_hazard.R")
#' @param manifest Manifest structure from read_test_manifest()
#' @return Logical indicating protection status
#' @export
is_protected <- function(test_filename, manifest) {
  if (is.null(manifest$files) || length(manifest$files) == 0) {
    return(FALSE)
  }

  file_entry <- manifest$files[[test_filename]]
  if (is.null(file_entry)) {
    return(FALSE)
  }

  isTRUE(file_entry$status == "protected")
}

#' Check if R file calls generic request functions
#'
#' @description
#' Uses parse() + all.names() to detect if a file calls:
#' - generic_request
#' - generic_chemi_request
#' - generic_cc_request
#'
#' @param file_path Path to R source file
#' @return Logical indicating if file calls generic request functions
#' @export
calls_generic_request <- function(file_path) {
  tryCatch({
    # Parse the R file
    exprs <- parse(file = file_path)

    # Extract all names (function calls) from all expressions
    all_names_in_file <- character(0)
    for (expr in exprs) {
      names_in_expr <- all.names(expr, functions = TRUE)
      all_names_in_file <- c(all_names_in_file, names_in_expr)
    }

    # Check if any generic request function is present
    generic_funcs <- c("generic_request", "generic_chemi_request", "generic_cc_request")
    any(generic_funcs %in% all_names_in_file)

  }, error = function(e) {
    # If file can't be parsed, assume it doesn't call generic_request
    cli::cli_alert_warning("Could not parse {file_path}: {e$message}")
    FALSE
  })
}

#' Check if test file has real test_that() blocks
#'
#' @description
#' Reads test file and checks for test_that() function calls
#'
#' @param test_file_path Path to test file
#' @return Logical indicating if test file has test_that() blocks
#' @export
has_real_tests <- function(test_file_path) {
  if (!file.exists(test_file_path)) {
    return(FALSE)
  }

  tryCatch({
    lines <- readLines(test_file_path, warn = FALSE)
    any(grepl("test_that\\s*\\(", lines))
  }, error = function(e) {
    cli::cli_alert_warning("Could not read {test_file_path}: {e$message}")
    FALSE
  })
}

#' Detect stale protected entries in manifest
#'
#' @description
#' Checks if protected test files in the manifest:
#' - Still have corresponding R/ function files
#' - Still call generic_request functions
#'
#' @param manifest Manifest structure from read_test_manifest()
#' @return List of stale entries with reason
#' @export
detect_stale_protected <- function(manifest) {
  if (is.null(manifest$files) || length(manifest$files) == 0) {
    return(list())
  }

  stale <- list()

  for (test_filename in names(manifest$files)) {
    entry <- manifest$files[[test_filename]]

    # Only check protected files
    if (!isTRUE(entry$status == "protected")) {
      next
    }

    # Extract function name from test filename (test-ct_hazard.R -> ct_hazard)
    function_name <- sub("^test-", "", sub("\\.R$", "", test_filename))
    r_file <- here::here("R", paste0(function_name, ".R"))

    # Check if R file exists
    if (!file.exists(r_file)) {
      stale[[test_filename]] <- list(
        test_file = test_filename,
        reason = "r_file_missing",
        details = paste0("R file not found: ", r_file)
      )
      next
    }

    # Check if R file still calls generic_request
    if (!calls_generic_request(r_file)) {
      stale[[test_filename]] <- list(
        test_file = test_filename,
        reason = "not_api_wrapper",
        details = "R file no longer calls generic_request"
      )
    }
  }

  stale
}

#' Main gap detection function
#'
#' @description
#' Scans R/ for API wrapper functions, detects test gaps, writes report.
#'
#' @return List of gap objects (returned invisibly)
#' @export
detect_gaps <- function() {
  cli::cli_h1("Test Gap Detection")

  # Load manifest
  manifest <- read_test_manifest()

  # Scan R/ for API wrapper files
  all_r_files <- fs::dir_ls(here::here("R"), regexp = "\\.R$")
  r_files <- all_r_files[grepl("^(ct_|chemi_|cc_)", basename(all_r_files))]

  cli::cli_alert_info("Scanning {length(r_files)} candidate files matching ct_/chemi_/cc_ pattern...")

  gaps <- list()

  for (r_file in r_files) {
    # Extract function name from filename
    function_name <- tools::file_path_sans_ext(basename(r_file))

    # Check if this is an API wrapper (calls generic_request)
    if (!calls_generic_request(r_file)) {
      # Skip non-API utility functions
      next
    }

    # Check for test file
    test_file <- here::here("tests", "testthat", paste0("test-", function_name, ".R"))
    test_filename <- paste0("test-", function_name, ".R")

    # Check if protected in manifest
    if (is_protected(test_filename, manifest)) {
      # Skip protected files (they're manually maintained)
      next
    }

    # Detect gap conditions
    if (!file.exists(test_file)) {
      gaps[[function_name]] <- list(
        function_name = function_name,
        file_path = as.character(r_file),
        test_file = as.character(test_file),
        reason = "no_test_file"
      )
    } else if (!has_real_tests(test_file)) {
      gaps[[function_name]] <- list(
        function_name = function_name,
        file_path = as.character(r_file),
        test_file = as.character(test_file),
        reason = "empty_test_file"
      )
    }
  }

  # Check for stale protected entries
  stale <- detect_stale_protected(manifest)
  if (length(stale) > 0) {
    cli::cli_alert_warning("Found {length(stale)} stale protected entries in manifest")
    for (entry in stale) {
      cli::cli_alert_warning("  {entry$test_file}: {entry$details}")
    }
  }

  # Generate report
  timestamp <- format(Sys.time(), "%Y%m%d", tz = "UTC")
  report_dir <- here::here("dev", "reports")
  if (!dir.exists(report_dir)) {
    dir.create(report_dir, recursive = TRUE)
  }

  report_file <- file.path(report_dir, paste0("test_gaps_", timestamp, ".json"))

  # Write report
  report_data <- list(
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    gaps_count = length(gaps),
    gaps = gaps,
    stale_protected = stale
  )

  jsonlite::write_json(
    report_data,
    report_file,
    pretty = TRUE,
    auto_unbox = TRUE
  )

  cli::cli_alert_success("Report written: {report_file}")

  # Write GITHUB_OUTPUT if in CI
  if (Sys.getenv("GITHUB_OUTPUT") != "") {
    output_file <- Sys.getenv("GITHUB_OUTPUT")
    cat(sprintf("gaps_found=%s\n", ifelse(length(gaps) > 0, "true", "false")),
        file = output_file, append = TRUE)
    cat(sprintf("gaps_count=%d\n", length(gaps)),
        file = output_file, append = TRUE)
    cli::cli_alert_success("GITHUB_OUTPUT variables written")
  }

  # Print summary
  cli::cli_h2("Summary")
  cli::cli_alert_info("Total gaps found: {length(gaps)}")

  if (length(gaps) > 0) {
    # Group by reason
    no_test <- sum(sapply(gaps, function(x) x$reason == "no_test_file"))
    empty_test <- sum(sapply(gaps, function(x) x$reason == "empty_test_file"))

    if (no_test > 0) {
      cli::cli_alert_warning("Missing test files: {no_test}")
      for (gap in gaps) {
        if (gap$reason == "no_test_file") {
          cli::cli_text("  - {gap$function_name}")
        }
      }
    }

    if (empty_test > 0) {
      cli::cli_alert_warning("Empty test files: {empty_test}")
      for (gap in gaps) {
        if (gap$reason == "empty_test_file") {
          cli::cli_text("  - {gap$function_name}")
        }
      }
    }
  } else {
    cli::cli_alert_success("No test gaps detected!")
  }

  invisible(gaps)
}

# Script entry point
if (!interactive()) {
  detect_gaps()
}
