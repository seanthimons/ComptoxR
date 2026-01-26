# ==============================================================================
# Remove Experimental Functions
# ==============================================================================
#
# This script finds and removes R files containing the experimental lifecycle badge.
# Useful for testing the endpoint evaluation workflow by clearing generated stubs.
#
# Usage:
#   source("remove_experimental.R")
#
# Safety:
#   - Lists files before deletion
#   - Requires confirmation before proceeding
#   - Set dry_run = TRUE to preview without deleting
#
# ==============================================================================

library(tidyverse)

# Configuration
dry_run <- FALSE  # Set to TRUE to preview without deleting
target_dir <- "R"  # Directory to search

# Pattern to match experimental badge in roxygen comments
experimental_pattern <- '`r lifecycle::badge\\("experimental"\\)`'

# ==============================================================================
# Find files with experimental badge
# ==============================================================================

cat("Searching for files with experimental lifecycle badge...\n\n")

# Get all R files
r_files <- list.files(target_dir, pattern = "\\.R$", full.names = TRUE) %>% 
	.[grep('^ct_*', basename(.), invert = F)]

# Check each file for experimental badge
experimental_files <- character()

for (file in r_files) {
  content <- readLines(file, warn = FALSE)
  if (any(str_detect(content, fixed('lifecycle::badge("experimental")')))) {
    experimental_files <- c(experimental_files, file)
  }
}

# ==============================================================================
# Report findings
# ==============================================================================

if (length(experimental_files) == 0) {
  cat("No files with experimental badge found.\n")
} else {

cat("Found", length(experimental_files), "file(s) with experimental badge:\n\n")

# Create a summary table
experimental_summary <- tibble(
  file = experimental_files,
  filename = basename(file),
  size_kb = file.size(file) / 1024
) %>%
  arrange(filename)

print(experimental_summary, n = Inf)

cat("\nTotal files:", nrow(experimental_summary), "\n")
cat("Total size:", round(sum(experimental_summary$size_kb), 2), "KB\n\n")

# ==============================================================================
# Delete files (with confirmation)
# ==============================================================================

if (dry_run) {
  cat("DRY RUN MODE: No files will be deleted.\n")
  cat("Set dry_run = FALSE to actually delete files.\n")
} else {
  cat("WARNING: This will permanently delete", length(experimental_files), "files.\n")
  cat("Type 'yes' to confirm deletion: ")

  # Read user confirmation
  response <- readline()

  if (tolower(trimws(response)) == "yes") {
    cat("\nDeleting files...\n")

    deleted_count <- 0
    failed_count <- 0

    for (file in experimental_files) {
      result <- tryCatch({
        file.remove(file)
        TRUE
      }, error = function(e) {
        cat("  ERROR:", file, "-", e$message, "\n")
        FALSE
      })

      if (result) {
        cat("  Deleted:", file, "\n")
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

}  # End of else block (files found)

# ==============================================================================
# Cleanup
# ==============================================================================

# Remove all variables created by this script
rm(
  dry_run,
  target_dir,
  experimental_pattern,
  r_files,
  experimental_files,
  file
)

# Remove conditional variables if they exist
if (exists("content")) rm(content)
if (exists("experimental_summary")) rm(experimental_summary)
if (exists("response")) rm(response)
if (exists("deleted_count")) rm(deleted_count)
if (exists("failed_count")) rm(failed_count)
if (exists("result")) rm(result)
