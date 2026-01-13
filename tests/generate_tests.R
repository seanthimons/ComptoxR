#!/usr/bin/env Rscript
# Quick-start script to generate test files for all wrapper functions
#
# This script provides two modes for test generation:
#   1. Schema-driven discovery (NEW): Automatically discovers functions from R/
#      and infers test case types from parameter names
#   2. Manual mapping (LEGACY): Uses hardcoded function_signatures list
#
# Usage:
#   Rscript generate_tests.R
#
# Or from R console:
#   source("generate_tests.R")
#
# Preferred method (schema-driven):
#   generate_tests_from_schema()
#
# Legacy method (manual mapping):
#   generate_tests()

library(ComptoxR)

# Load the test generator helper
source("tests/testthat/helper-test-generator.R")

# Configuration
TEST_DIR <- "tests/testthat"
R_DIR <- "R"

# ==============================================================================
# Schema-Driven Test Generation (Recommended)
# ==============================================================================

#' Generate tests by discovering wrapper functions from the R/ directory
#'
#' This is the preferred method for generating tests. It automatically:
#' - Discovers all ct_* and chemi_* wrapper functions from R/ source files
#' - Infers parameter types from the first parameter name (e.g., "query" -> dtxsid)
#' - Selects appropriate test case templates based on inferred types
#' - Generates test files for functions that don't have tests yet
#'
#' When new functions are generated from OpenAPI schemas, simply run this
#' function to automatically generate tests for them.
#'
#' @param overwrite If TRUE, regenerate all test files even if they exist.
#' @param dry_run If TRUE, only report what would be generated without creating files.
#' @return A list with elements: created, skipped, failed (character vectors of function names).
#' @export
#' @examples
#' \dontrun{
#' # See what new tests would be generated
#' generate_tests_from_schema(dry_run = TRUE)
#'
#' # Generate tests for all new/untested functions
#' generate_tests_from_schema()
#'
#' # Regenerate all tests
#' generate_tests_from_schema(overwrite = TRUE)
#' }
generate_tests_from_schema <- function(overwrite = FALSE, dry_run = FALSE) {
  cat("═══════════════════════════════════════════════\n")
  cat("Schema-Driven Test Generation\n")
  cat("═══════════════════════════════════════════════\n\n")

  result <- generate_schema_discovered_tests(
    r_dir = R_DIR,
    test_dir = TEST_DIR,
    overwrite = overwrite,
    dry_run = dry_run
  )

  if (length(result$created) > 0) {
    cat("\nNext steps:\n")
    cat("1. Set API key: Sys.setenv(ctx_api_key = 'YOUR_KEY')\n")
    cat("2. Run tests to record cassettes: devtools::test()\n")
    cat("3. Check coverage: covr::package_coverage()\n")
    cat("4. Review and commit cassettes\n")
  }

  invisible(result)
}

# ==============================================================================
# Legacy Test Generation (Manual Mapping)
# ==============================================================================

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

# Function signature mapping (LEGACY)
# Maps function names to their expected parameter types
# NOTE: For new functions, consider using generate_tests_from_schema() instead
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

#' Generate tests using manual function signature mapping (Legacy)
#'
#' This is the legacy method that uses a hardcoded list of function signatures.
#' For new development, prefer generate_tests_from_schema() which automatically
#' discovers functions and infers their parameter types.
#'
#' @param functions_to_test Character vector of function names. If NULL, uses all ct_* and chemi_* functions.
#' @param overwrite If TRUE, overwrite existing test files.
#' @return A list with elements: created, skipped, failed (character vectors of function names).
#' @export
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

# ==============================================================================
# Script Execution
# ==============================================================================

# Run if executed as script (use schema-driven by default)
if (!interactive()) {
  generate_tests_from_schema()
}

# Example usage for interactive sessions:
if (interactive()) {
  cat("\nTest generator loaded!\n\n")
  cat("═══════════════════════════════════════════════\n")
  cat("RECOMMENDED: Schema-driven test generation\n")
  cat("═══════════════════════════════════════════════\n\n")
  cat("To see what tests would be generated (dry run):\n")
  cat("  generate_tests_from_schema(dry_run = TRUE)\n\n")
  cat("To generate tests for new functions:\n")
  cat("  generate_tests_from_schema()\n\n")
  cat("To regenerate all tests:\n")
  cat("  generate_tests_from_schema(overwrite = TRUE)\n\n")
  cat("═══════════════════════════════════════════════\n")
  cat("LEGACY: Manual function mapping\n")
  cat("═══════════════════════════════════════════════\n\n")
  cat("To generate tests using manual mapping:\n")
  cat("  generate_tests()\n\n")
  cat("To generate tests for specific functions:\n")
  cat("  generate_tests(c('ct_hazard', 'ct_cancer'))\n\n")
  cat("To overwrite existing test files:\n")
  cat("  generate_tests(overwrite = TRUE)\n\n")
}
