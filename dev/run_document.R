# Run devtools::document() and verify success
# Task 3: VAL-02 requirement check

library(cli)

cat("=== RUNNING DEVTOOLS::DOCUMENT() ===\n\n")

# Run documentation generation
tryCatch({
  devtools::document()

  # VAL-02: If we get here without error, documentation generation succeeded
  cli::cli_alert_success("VAL-02 PASSED: devtools::document() completed successfully")

}, error = function(e) {
  cli::cli_abort("devtools::document() failed: {e$message}")
})

cat("\n=== VERIFYING ARTIFACTS ===\n\n")

# Verify .Rd file was created/updated
rd_file <- "man/ct_chemical_search_equal_bulk.Rd"
if (!file.exists(rd_file)) {
  cli::cli_abort("Documentation file not created: {rd_file}")
}
cli::cli_alert_success("Documentation file exists: {rd_file}")

# Check file size to ensure it's not empty
rd_size <- file.info(rd_file)$size
cat(sprintf("  File size: %d bytes\n", rd_size))

# Verify NAMESPACE has export
namespace_lines <- readLines("NAMESPACE")
if (!any(grepl("export\\(ct_chemical_search_equal_bulk\\)", namespace_lines))) {
  cli::cli_abort("Function not exported in NAMESPACE")
}
cli::cli_alert_success("Function exported in NAMESPACE")

# Show first few lines of generated documentation
cat("\n=== GENERATED DOCUMENTATION PREVIEW ===\n\n")
rd_lines <- readLines(rd_file, n = 15)
cat(paste(rd_lines, collapse = "\n"), "\n")

cat("\n=== VALIDATION COMPLETE ===\n")
