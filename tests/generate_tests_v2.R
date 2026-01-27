#!/usr/bin/env Rscript
# Metadata-Based Test Generator for ComptoxR
#
# This script generates test files based on actual function signatures,
# return types, and documentation extracted from the source code.
#
# Usage:
#   Rscript generate_tests_v2.R
#
# Or from R console:
#   source("tests/generate_tests_v2.R")

library(ComptoxR)

# Load the test generator helpers
source("tests/testthat/helper-function-metadata.R")
source("tests/testthat/helper-test-generator-v2.R")

# Configuration
TEST_DIR <- "tests/testthat"
R_DIR <- "R"

#' Main test generation function with metadata extraction
#'
#' @param functions_to_test Vector of function names (NULL for all)
#' @param overwrite Overwrite existing test files
#' @param verbose Print detailed progress
#' @return Summary of results
generate_tests_with_metadata <- function(functions_to_test = NULL,
                                         overwrite = FALSE,
                                         verbose = TRUE) {

  # Extract metadata for all functions
  if (verbose) {
    cat("═══════════════════════════════════════════════\n")
    cat("Extracting function metadata from source files\n")
    cat("═══════════════════════════════════════════════\n\n")
  }

  all_metadata <- extract_all_metadata(R_DIR)

  if (verbose) {
    cat("Found", length(all_metadata), "functions\n\n")
  }

  # Filter to requested functions if specified
  if (!is.null(functions_to_test)) {
    all_metadata <- all_metadata[names(all_metadata) %in% functions_to_test]

    if (length(all_metadata) == 0) {
      stop("No matching functions found")
    }
  }

  # Results tracking
  results <- list(
    created = character(),
    skipped = character(),
    failed = character(),
    metadata = list()
  )

  # Get standard test inputs
  test_inputs <- get_standard_test_inputs()

  if (verbose) {
    cat("Generating tests...\n\n")
  }

  # Generate test for each function
  for (fn_name in names(all_metadata)) {
    metadata <- all_metadata[[fn_name]]
    test_file <- file.path(TEST_DIR, paste0("test-", fn_name, ".R"))

    # Skip if file exists and overwrite is FALSE
    if (file.exists(test_file) && !overwrite) {
      if (verbose) {
        cat("⊗ Skipped", fn_name, "(file exists)\n")
      }
      results$skipped <- c(results$skipped, fn_name)
      next
    }

    # Generate test file
    tryCatch({
      create_metadata_based_test_file(
        metadata = metadata,
        output_file = test_file,
        test_inputs = test_inputs
      )

      if (verbose) {
        cat("✓ Created", fn_name, "\n")
        cat("  Return type:", metadata$return_type$type, "\n")

        if (length(metadata$function_def$params) > 0) {
          param_names <- names(metadata$function_def$params)
          cat("  Parameters:", paste(param_names, collapse = ", "), "\n")
        }

        if (length(metadata$examples) > 0) {
          cat("  Examples: ✓\n")
        }

        cat("\n")
      }

      results$created <- c(results$created, fn_name)
      results$metadata[[fn_name]] <- metadata

    }, error = function(e) {
      if (verbose) {
        cat("✗ Failed", fn_name, ":", conditionMessage(e), "\n\n")
      }
      results$failed <- c(results$failed, fn_name)
    })
  }

  # Print summary
  if (verbose) {
    cat("\n")
    cat("═══════════════════════════════════════════════\n")
    cat("Summary\n")
    cat("═══════════════════════════════════════════════\n\n")

    cat("Created:", length(results$created), "test files\n")
    cat("Skipped:", length(results$skipped), "test files (already exist)\n")
    cat("Failed:", length(results$failed), "test files\n\n")

    # Return type breakdown
    if (length(results$metadata) > 0) {
      return_types <- sapply(results$metadata, function(m) m$return_type$type)
      type_table <- table(return_types)

      cat("Return type distribution:\n")
      for (type in names(type_table)) {
        cat("  ", type, ":", type_table[type], "\n")
      }
      cat("\n")
    }

    if (length(results$failed) > 0) {
      cat("Failed functions:\n")
      for (fn in results$failed) {
        cat("  - ", fn, "\n")
      }
      cat("\n")
    }

    cat("═══════════════════════════════════════════════\n")
    cat("Next Steps\n")
    cat("═══════════════════════════════════════════════\n\n")

    if (length(results$created) > 0) {
      cat("1. Set API key: Sys.setenv(ctx_api_key = 'YOUR_KEY')\n")
      cat("2. Run tests to record cassettes: devtools::test()\n")
      cat("3. Review generated tests for accuracy\n")
      cat("4. Check coverage: covr::package_coverage()\n")
      cat("5. Commit tests and cassettes\n\n")
    }
  }

  invisible(results)
}

#' Regenerate specific function tests
regenerate_function_tests <- function(function_names, verbose = TRUE) {
  generate_tests_with_metadata(
    functions_to_test = function_names,
    overwrite = TRUE,
    verbose = verbose
  )
}

#' Preview test for a single function without writing
preview_test <- function(fn_name) {
  metadata <- extract_function_metadata(file.path(R_DIR, paste0(fn_name, ".R")))

  cat("═══════════════════════════════════════════════\n")
  cat("Function:", fn_name, "\n")
  cat("═══════════════════════════════════════════════\n\n")

  cat("Return type:", metadata$return_type$type, "\n")
  cat("Description:", metadata$return_type$description, "\n\n")

  if (length(metadata$function_def$params) > 0) {
    cat("Parameters:\n")
    for (param in metadata$function_def$params) {
      required <- if (param$required) "(required)" else "(optional)"
      default <- if (!is.null(param$default)) paste("=", param$default) else ""
      cat("  -", param$name, default, required, "\n")
    }
    cat("\n")
  }

  if (length(metadata$examples) > 0) {
    cat("Examples:\n")
    for (ex in metadata$examples) {
      cat("  ", ex, "\n")
    }
    cat("\n")
  }

  cat("═══════════════════════════════════════════════\n")
  cat("Generated Test Preview:\n")
  cat("═══════════════════════════════════════════════\n\n")

  create_metadata_based_test_file(
    metadata = metadata,
    output_file = NULL
  )
}

# Run if executed as script
if (!interactive()) {
  results <- generate_tests_with_metadata()

  # Exit with error code if failures occurred
  if (length(results$failed) > 0) {
    quit(status = 1)
  }
}

# Interactive usage examples
if (interactive()) {
  cat("\n═══════════════════════════════════════════════\n")
  cat("Metadata-Based Test Generator Loaded\n")
  cat("═══════════════════════════════════════════════\n\n")

  cat("Generate all tests:\n")
  cat("  generate_tests_with_metadata()\n\n")

  cat("Generate tests for specific functions:\n")
  cat("  generate_tests_with_metadata(c('ct_hazard', 'ct_list'))\n\n")

  cat("Overwrite existing test files:\n")
  cat("  generate_tests_with_metadata(overwrite = TRUE)\n\n")

  cat("Regenerate specific function tests:\n")
  cat("  regenerate_function_tests(c('ct_hazard'))\n\n")

  cat("Preview test without writing:\n")
  cat("  preview_test('ct_hazard')\n\n")
}
