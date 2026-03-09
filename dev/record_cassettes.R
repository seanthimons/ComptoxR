#!/usr/bin/env Rscript
# Parallel cassette recording script using mirai
# Re-records all VCR cassettes from production API

library(cli)
library(mirai)
library(fs)

# Configuration
N_WORKERS <- 4  # Conservative to avoid EPA API rate limiting
FAILURE_THRESHOLD <- 0.15  # Halt if >15% fail (systemic issue detection)

# Dry-run mode check
DRY_RUN <- tolower(Sys.getenv("DRY_RUN")) == "true"

if (DRY_RUN) {
  cli_alert_info("Running in DRY RUN mode - validations only, no cassette recording")
}

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

cli_h1("Pre-flight Checks")

# Check 1: API key
cli_alert_info("Checking API key...")
if (!nzchar(Sys.getenv("ctx_api_key"))) {
  cli_abort(c(
    "x" = "ctx_api_key environment variable not set",
    "i" = "Request API key from ccte_api@epa.gov",
    "i" = "Set with: Sys.setenv(ctx_api_key = 'YOUR_KEY')"
  ))
}
cli_alert_success("API key found")

# Check 2: mirai availability
cli_alert_info("Checking mirai package...")
if (!requireNamespace("mirai", quietly = TRUE)) {
  cli_abort(c(
    "x" = "mirai package not installed",
    "i" = "Install with: install.packages('mirai')"
  ))
}
cli_alert_success("mirai available (version {packageVersion('mirai')})")

# Check 3: fixtures directory
cli_alert_info("Checking fixtures directory...")
fixtures_dir <- here::here("tests/testthat/fixtures")
if (!dir.exists(fixtures_dir)) {
  cli_abort(c(
    "x" = "Fixtures directory not found: {fixtures_dir}"
  ))
}
cli_alert_success("Fixtures directory exists")

# ==============================================================================
# Cassette Discovery and Family Grouping
# ==============================================================================

cli_h1("Cassette Discovery")

# List all cassettes
all_cassettes <- fs::dir_ls(fixtures_dir, glob = "*.yml")
cli_alert_info("Found {length(all_cassettes)} cassette files")

if (length(all_cassettes) == 0) {
  cli_abort("No cassettes found in {fixtures_dir}")
}

# Extract major families from filenames
# Convention: {super_family}_{major_family}_{group}_{variant}.yml
# e.g., ct_bioactivity_assay_search_by_aeid_example.yml -> ct_bioactivity

extract_major_family <- function(cassette_path) {
  filename <- fs::path_file(cassette_path)
  parts <- strsplit(filename, "_")[[1]]
  if (length(parts) >= 2) {
    paste(parts[1], parts[2], sep = "_")
  } else {
    parts[1]  # Fallback for single-part names
  }
}

cassette_families <- vapply(all_cassettes, extract_major_family, character(1))
families <- unique(cassette_families)

# Group cassettes by family
family_groups <- lapply(families, function(fam) {
  all_cassettes[cassette_families == fam]
})
names(family_groups) <- families

cli_alert_success("Organized into {length(families)} major families:")
for (fam in families) {
  n <- length(family_groups[[fam]])
  cli_alert_info("  {fam}: {n} cassette{?s}")
}

# ==============================================================================
# Cassette-to-Test-File Mapping
# ==============================================================================

cli_h1("Mapping Cassettes to Test Files")

# Find test files
test_dir <- here::here("tests/testthat")
test_files <- fs::dir_ls(test_dir, regexp = "test-.*\\.R$")
cli_alert_info("Found {length(test_files)} test files")

# Cache for test file contents
test_file_cache <- list()

# Map cassette to test file
find_test_for_cassette <- function(cassette_path) {
  cassette_name <- fs::path_file(cassette_path)
  cassette_base <- fs::path_ext_remove(cassette_name)

  # Search test files for use_cassette calls
  for (test_file in test_files) {
    # Read file contents (cache to avoid re-reading)
    if (is.null(test_file_cache[[test_file]])) {
      test_file_cache[[test_file]] <<- readLines(test_file, warn = FALSE)
    }

    lines <- test_file_cache[[test_file]]

    # Look for use_cassette("cassette_base", ...)
    pattern <- paste0('use_cassette\\s*\\(\\s*["\']', cassette_base, '["\']')
    if (any(grepl(pattern, lines))) {
      return(test_file)
    }
  }

  NULL  # No test file found
}

# Build mapping
cli_alert_info("Building cassette-to-test-file mapping...")
cassette_to_test <- list()
unmapped_count <- 0

for (cassette in all_cassettes) {
  test_file <- find_test_for_cassette(cassette)
  if (!is.null(test_file)) {
    cassette_to_test[[cassette]] <- test_file
  } else {
    unmapped_count <- unmapped_count + 1
    cli_alert_warning("No test file found for: {fs::path_file(cassette)}")
  }
}

cli_alert_success("Mapped {length(cassette_to_test)} cassettes to test files")
if (unmapped_count > 0) {
  cli_alert_warning("Could not map {unmapped_count} cassette{?s} - will skip")
}

# ==============================================================================
# Dry-Run Exit Point
# ==============================================================================

if (DRY_RUN) {
  cli_h1("Dry-Run Validation Complete")

  # Test mirai daemon initialization
  cli_alert_info("Testing mirai daemon initialization...")
  daemons(n = N_WORKERS)
  cli_alert_success("Mirai daemons initialized ({N_WORKERS} workers)")

  # Shutdown immediately
  daemons(0)
  cli_alert_success("Mirai daemons shut down cleanly")

  cli_rule()
  cli_alert_success("DRY RUN COMPLETE - all validations passed")
  cli_alert_info("Set DRY_RUN=false or unset to run actual recording")
  quit(status = 0)
}

# ==============================================================================
# Parallel Recording with mirai
# ==============================================================================

cli_h1("Recording Cassettes")

# Initialize daemon pool
cli_alert_info("Initializing {N_WORKERS} mirai workers...")
daemons(n = N_WORKERS)
cli_alert_success("Workers ready")

# Create reports directory
reports_dir <- here::here("dev/reports")
fs::dir_create(reports_dir, recurse = TRUE)

# Open log file
log_file <- fs::path(reports_dir, "cassette_recording_log.txt")
log_conn <- file(log_file, "w")
writeLines(paste("Cassette Recording Log -", Sys.time()), log_conn)
writeLines("", log_conn)

# Track overall results
all_results <- list()

# Process each family sequentially (parallel within family)
for (family in families) {
  cli_h2("Family: {family}")

  family_cassettes <- family_groups[[family]]
  n_cassettes <- length(family_cassettes)

  # Filter to only cassettes with known test files
  cassettes_to_record <- family_cassettes[family_cassettes %in% names(cassette_to_test)]
  n_skipped <- n_cassettes - length(cassettes_to_record)

  if (length(cassettes_to_record) == 0) {
    cli_alert_warning("No mappable cassettes in family {family} - skipping")
    next
  }

  cli_alert_info("Recording {length(cassettes_to_record)} cassette{?s} ({n_skipped} skipped)")

  # Delete existing cassettes for this family
  for (cassette in cassettes_to_record) {
    if (fs::file_exists(cassette)) {
      fs::file_delete(cassette)
    }
  }

  # Submit parallel tasks
  family_results <- mirai_map(
    cassettes_to_record,
    function(cassette_path) {
      tryCatch({
        # Load required libraries in worker
        library(testthat)

        # Get test file from mapping (passed via closure)
        test_file <- cassette_to_test_map[[cassette_path]]

        # Run test file (this records the cassette via VCR)
        test_result <- testthat::test_file(test_file, reporter = "minimal")

        list(
          success = TRUE,
          cassette = cassette_path,
          test_file = test_file
        )
      }, error = function(e) {
        list(
          success = FALSE,
          cassette = cassette_path,
          error = e$message
        )
      })
    },
    .args = list(cassette_to_test_map = cassette_to_test)
  )

  # Analyze results
  successes <- sum(vapply(family_results, function(r) r$success, logical(1)))
  failures <- length(family_results) - successes
  failure_rate <- failures / length(family_results)

  # Log results
  writeLines(paste("Family:", family), log_conn)
  writeLines(paste("  Total:", length(family_results)), log_conn)
  writeLines(paste("  Success:", successes), log_conn)
  writeLines(paste("  Failures:", failures), log_conn)
  writeLines(paste("  Failure rate:", sprintf("%.1f%%", failure_rate * 100)), log_conn)
  writeLines("", log_conn)

  # Store results
  all_results[[family]] <- list(
    total = length(family_results),
    successes = successes,
    failures = failures,
    failure_rate = failure_rate,
    results = family_results
  )

  # Report
  if (failures > 0) {
    cli_alert_warning("{failures} failure{?s} ({sprintf('%.1f%%', failure_rate * 100)})")

    # Log failed cassettes
    for (result in family_results) {
      if (!result$success) {
        cli_alert_danger("  {fs::path_file(result$cassette)}: {result$error}")
        writeLines(paste("  FAIL:", fs::path_file(result$cassette), "-", result$error), log_conn)
      }
    }
  } else {
    cli_alert_success("All {successes} cassette{?s} recorded successfully")
  }

  # Check failure threshold
  if (failure_rate > FAILURE_THRESHOLD) {
    cli_alert_danger("Failure rate {sprintf('%.1f%%', failure_rate * 100)} exceeds threshold ({sprintf('%.1f%%', FAILURE_THRESHOLD * 100)})")
    cli_alert_warning("Halting - likely systemic issue (expired key, API outage, schema change)")

    writeLines("", log_conn)
    writeLines("HALTED DUE TO FAILURE THRESHOLD", log_conn)
    writeLines(paste("Family:", family, "- Failure rate:", sprintf("%.1f%%", failure_rate * 100)), log_conn)

    # Cleanup and exit
    close(log_conn)
    daemons(0)
    cli_abort("Recording halted due to high failure rate")
  }
}

# Close log file
writeLines("", log_conn)
writeLines(paste("Recording completed at", Sys.time()), log_conn)
close(log_conn)

# ==============================================================================
# Summary
# ==============================================================================

cli_h1("Recording Summary")

# Calculate totals
total_cassettes <- sum(vapply(all_results, function(r) r$total, integer(1)))
total_successes <- sum(vapply(all_results, function(r) r$successes, integer(1)))
total_failures <- sum(vapply(all_results, function(r) r$failures, integer(1)))
overall_failure_rate <- total_failures / total_cassettes

# Display summary table
cli_alert_info("Overall Results:")
cli_alert_info("  Total cassettes: {total_cassettes}")
cli_alert_info("  Successful: {total_successes}")
cli_alert_info("  Failed: {total_failures}")
cli_alert_info("  Failure rate: {sprintf('%.1f%%', overall_failure_rate * 100)}")

# Per-family summary
cli_rule("Per-Family Results")
for (family in names(all_results)) {
  r <- all_results[[family]]
  cli_alert_info("{family}: {r$successes}/{r$total} ({sprintf('%.1f%%', (1 - r$failure_rate) * 100)} success)")
}

cli_alert_success("Log written to: {log_file}")

# Cleanup workers
daemons(0)
cli_alert_success("Mirai workers shut down")

# ==============================================================================
# Post-Recording Health Check
# ==============================================================================

cli_h1("Running Post-Recording Health Check")

health_check_script <- here::here("dev/check_cassette_health.R")
if (fs::file_exists(health_check_script)) {
  cli_alert_info("Running {health_check_script}...")
  system2("Rscript", args = health_check_script)
} else {
  cli_alert_warning("Health check script not found: {health_check_script}")
}

cli_rule()
cli_alert_success("Recording complete!")
