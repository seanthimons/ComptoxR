#!/usr/bin/env Rscript
# Quick-start script to generate test files for all wrapper functions
#
# Usage:
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
test_cases <- list(
  # Functions that take dtxsid parameter
  dtxsid_single = list(
    valid = list(dtxsid = "DTXSID7020182"),
    batch = c("DTXSID7020182", "DTXSID5032381", "DTXSID8024291"),
    invalid = "INVALID_DTXSID"
  ),

  # Functions that take cas parameter
  cas_single = list(
    valid = list(cas = "50-00-0"),
    batch = c("50-00-0", "108-88-3", "71-43-2"),
    invalid = "INVALID-CAS"
  ),

  # Functions that take smiles parameter
  smiles_single = list(
    valid = list(smiles = "C=O"),
    batch = c("C=O", "c1ccccc1", "CCO"),
    invalid = "INVALID_SMILES"
  ),

  # Functions that take list name parameter
  list_name = list(
    valid = list(listname = "PRODWATER"),
    batch = NULL,
    invalid = "NONEXISTENT_LIST"
  )
)

# Function signature mapping
# Maps function names to their expected parameter types
function_signatures <- list(
  # DTXSID-based functions
  ct_hazard = "dtxsid_single",
  ct_cancer = "dtxsid_single",
  ct_genotox = "dtxsid_single",
  ct_skin_eye = "dtxsid_single",
  ct_details = "dtxsid_single",
  ct_synonym = "dtxsid_single",
  ct_ghs = "dtxsid_single",
  ct_properties = "dtxsid_single",
  ct_functional_use = "dtxsid_single",

  # Search functions
  ct_search = "smiles_single",
  ct_similar = "dtxsid_single",

  # List functions
  ct_list = "list_name",

  # Chemi functions (mostly DTXSID)
  chemi_toxprint = "dtxsid_single",
  chemi_safety = "dtxsid_single",
  chemi_hazard = "dtxsid_single",
  chemi_rq = "dtxsid_single",
  chemi_classyfire = "smiles_single",
  chemi_predict = "dtxsid_single"
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
      # Default to dtxsid if not specified
      sig_type <- "dtxsid_single"
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
