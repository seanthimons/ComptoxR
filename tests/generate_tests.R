#!/usr/bin/env Rscript
# Quick-start script to generate test files for all wrapper functions
#
# ⚠️  DEPRECATED - This is the OLD template-based test generator
#
# Please use the NEW metadata-based system instead:
#   source("tests/generate_tests_v2.R")
#   generate_tests_with_metadata()
#
# See tests/MIGRATION.md for migration instructions.
#
# This file is kept for backwards compatibility only.
#
# Usage (OLD SYSTEM - DEPRECATED):
#   Rscript generate_tests.R
#
# Or from R console:
#   source("generate_tests.R")

library(ComptoxR)

# Load the test generator helper
source("tests/testthat/helper-test-generator.R")

# Configuration
TEST_DIR <- "tests/testthat"

# Standard test cases for different function signatures
# Note: Most ct_ and chemi_ functions use 'query' as their parameter name
test_cases <- list(
  # Functions that take query parameter (most common)
  query_single = list(
    valid = list(query = "DTXSID7020182"),
    batch = c("DTXSID7020182", "DTXSID5032381", "DTXSID8024291"),
    invalid = "INVALID_DTXSID"
  ),

  # Functions that take list_name parameter
  list_name = list(
    valid = list(list_name = "PRODWATER"),
    batch = NULL,
    invalid = "NONEXISTENT_LIST"
  ),

  # Functions that take chemicals parameter
  chemicals = list(
    valid = list(chemicals = "benzene"),
    batch = c("benzene", "toluene", "xylene"),
    invalid = "INVALID_CHEMICAL_NAME_XYZ"
  )
)

# Function signature mapping
# Maps function names to their expected parameter types
function_signatures <- list(
  # Query-based functions (most common - use 'query' parameter)
  ct_hazard = "query_single",
  ct_cancer = "query_single",
  ct_genotox = "query_single",
  ct_skin_eye = "query_single",
  ct_details = "query_single",
  ct_synonym = "query_single",
  ct_ghs = "query_single",
  ct_search = "query_single",
  ct_similar = "query_single",
  ct_env_fate = "query_single",
  ct_test = "query_single",
  ct_related = "query_single",
  ct_compound_in_list = "query_single",

  # List functions
  ct_list = "list_name",

  # Chemi functions (mostly use 'query' parameter)
  chemi_toxprint = "query_single",
  chemi_safety = "query_single",
  chemi_hazard = "query_single",
  chemi_classyfire = "query_single",
  chemi_predict = "query_single",
  chemi_safety_section = "query_single",

  # Chemi functions with chemicals parameter
  chemi_cluster = "chemicals"
)

# Main test generation function
generate_tests <- function(functions_to_test = NULL, overwrite = FALSE) {

  if (is.null(functions_to_test)) {
    # Get all ct_ and chemi_ functions
    all_functions <- ls("package:ComptoxR")
    functions_to_test <- all_functions[grepl("^(ct_|chemi_)", all_functions)]

    # Exclude configuration functions
    functions_to_test <- setdiff(
      functions_to_test,
      c("ct_api_key", "ct_server", "chemi_server")
    )
  }

  cat("Generating tests for", length(functions_to_test), "functions...\n\n")

  results <- list(
    created = character(),
    skipped = character(),
    failed = character()
  )

  for (fn_name in functions_to_test) {
    test_file <- file.path(TEST_DIR, paste0("test-", fn_name, ".R"))

    # Skip if file exists and overwrite is FALSE
    if (file.exists(test_file) && !overwrite) {
      cat("⊗ Skipped", fn_name, "(file exists)\n")
      results$skipped <- c(results$skipped, fn_name)
      next
    }

    # Get test case template for this function
    sig_type <- function_signatures[[fn_name]]
    if (is.null(sig_type)) {
      # Default to query_single if not specified
      sig_type <- "query_single"
      cat("⚠ Using default test case for", fn_name, "\n")
    }

    test_case <- test_cases[[sig_type]]

    # Generate test file
    tryCatch({
      create_wrapper_test_file(
        fn_name = fn_name,
        valid_input = test_case$valid,
        batch_input = test_case$batch,
        invalid_input = test_case$invalid,
        output_file = test_file
      )
      cat("✓ Created", test_file, "\n")
      results$created <- c(results$created, fn_name)
    }, error = function(e) {
      cat("✗ Failed to create test for", fn_name, ":", conditionMessage(e), "\n")
      results$failed <- c(results$failed, fn_name)
    })
  }

  # Summary
  cat("\n")
  cat("═══════════════════════════════════════════════\n")
  cat("Summary:\n")
  cat("  Created:", length(results$created), "test files\n")
  cat("  Skipped:", length(results$skipped), "test files\n")
  cat("  Failed:", length(results$failed), "test files\n")
  cat("═══════════════════════════════════════════════\n")

  if (length(results$created) > 0) {
    cat("\nNext steps:\n")
    cat("1. Set API key: Sys.setenv(ctx_api_key = 'YOUR_KEY')\n")
    cat("2. Run tests to record cassettes: devtools::test()\n")
    cat("3. Check coverage: covr::package_coverage()\n")
    cat("4. Review and commit cassettes\n")
  }

  invisible(results)
}

# Run if executed as script
if (!interactive()) {
  generate_tests()
}

# Example usage for interactive sessions:
if (interactive()) {
  cat("\nTest generator loaded!\n\n")
  cat("To generate all tests:\n")
  cat("  generate_tests()\n\n")
  cat("To generate tests for specific functions:\n")
  cat("  generate_tests(c('ct_hazard', 'ct_cancer'))\n\n")
  cat("To overwrite existing test files:\n")
  cat("  generate_tests(overwrite = TRUE)\n\n")
}
