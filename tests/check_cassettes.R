#!/usr/bin/env Rscript
# Script to check VCR cassettes and identify orphans
#
# Usage:
#   Rscript check_cassettes.R
#
# This script:
# 1. Lists all VCR cassettes
# 2. Checks which tests reference them
# 3. Identifies orphaned cassettes (no matching test)
# 4. Provides cleanup recommendations

library(dplyr)

# Get all cassette files
cassette_dir <- "tests/testthat/fixtures"
cassettes <- list.files(cassette_dir, pattern = "\\.yml$", full.names = FALSE)

# Get all test files
test_files <- list.files("tests/testthat", pattern = "^test-.*\\.R$", full.names = TRUE)

cat("═══════════════════════════════════════════════════════════\n")
cat("VCR Cassette Analysis\n")
cat("═══════════════════════════════════════════════════════════\n\n")

cat("Found:", length(cassettes), "cassettes\n")
cat("Found:", length(test_files), "test files\n\n")

# Check each cassette
cassette_status <- data.frame(
  cassette = cassettes,
  referenced = FALSE,
  test_file = NA_character_,
  stringsAsFactors = FALSE
)

for (i in seq_along(cassettes)) {
  cassette_name <- sub("\\.yml$", "", cassettes[i])

  # Check which test files reference this cassette
  for (test_file in test_files) {
    test_content <- readLines(test_file, warn = FALSE)

    # Look for use_cassette calls with this cassette name
    if (any(grepl(cassette_name, test_content, fixed = TRUE))) {
      cassette_status$referenced[i] <- TRUE
      cassette_status$test_file[i] <- basename(test_file)
      break
    }
  }
}

# Summary
cat("═══════════════════════════════════════════════════════════\n")
cat("Summary:\n")
cat("═══════════════════════════════════════════════════════════\n\n")

referenced <- sum(cassette_status$referenced)
orphaned <- sum(!cassette_status$referenced)

cat("✓ Referenced cassettes:", referenced, "\n")
cat("✗ Orphaned cassettes:", orphaned, "\n\n")

if (orphaned > 0) {
  cat("═══════════════════════════════════════════════════════════\n")
  cat("Orphaned Cassettes (can be deleted):\n")
  cat("═══════════════════════════════════════════════════════════\n\n")

  orphaned_cassettes <- cassette_status %>%
    filter(!referenced) %>%
    pull(cassette)

  for (cass in orphaned_cassettes) {
    cat("  -", cass, "\n")
  }

  cat("\nTo delete orphaned cassettes:\n")
  cat("  source('check_cassettes.R')\n")
  cat("  delete_orphaned_cassettes()\n\n")
}

if (referenced > 0) {
  cat("═══════════════════════════════════════════════════════════\n")
  cat("Referenced Cassettes (keep these):\n")
  cat("═══════════════════════════════════════════════════════════\n\n")

  referenced_cassettes <- cassette_status %>%
    filter(referenced) %>%
    arrange(test_file, cassette)

  for (i in seq_len(nrow(referenced_cassettes))) {
    cat("  ✓", referenced_cassettes$cassette[i],
        "(used by", referenced_cassettes$test_file[i], ")\n")
  }
  cat("\n")
}

# Check for tests without cassettes
cat("═══════════════════════════════════════════════════════════\n")
cat("Tests Needing Cassettes:\n")
cat("═══════════════════════════════════════════════════════════\n\n")

tests_needing_cassettes <- character()

for (test_file in test_files) {
  test_content <- paste(readLines(test_file, warn = FALSE), collapse = "\n")

  # Find all use_cassette calls
  cassette_calls <- stringr::str_match_all(
    test_content,
    'use_cassette\\("([^"]+)"'
  )[[1]]

  if (nrow(cassette_calls) > 0) {
    expected_cassettes <- paste0(cassette_calls[, 2], ".yml")
    missing <- setdiff(expected_cassettes, cassettes)

    if (length(missing) > 0) {
      cat("  ", basename(test_file), "needs:\n")
      for (m in missing) {
        cat("    -", m, "\n")
      }
    }
  }
}

cat("\n")

# Function to delete orphaned cassettes
delete_orphaned_cassettes <- function() {
  orphaned <- cassette_status %>%
    filter(!referenced) %>%
    pull(cassette)

  if (length(orphaned) == 0) {
    cat("No orphaned cassettes to delete.\n")
    return(invisible())
  }

  cat("Deleting", length(orphaned), "orphaned cassettes...\n")

  for (cass in orphaned) {
    file_path <- file.path(cassette_dir, cass)
    if (file.exists(file_path)) {
      file.remove(file_path)
      cat("  ✓ Deleted:", cass, "\n")
    }
  }

  cat("\nDone! Deleted", length(orphaned), "cassettes.\n")
}

# Return status invisibly
invisible(cassette_status)
