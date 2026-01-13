# Test Template Generator for ComptoxR Wrapper Functions
#
# This helper provides utilities to generate standardized tests for API wrapper functions.
# Most wrapper functions follow similar patterns, so we can use template-based testing.

#' Generate a standard test for a simple wrapper function
#'
#' @param fn_name Function name (e.g., "ct_hazard")
#' @param test_inputs List of test inputs to pass to the function
#' @param expected_behavior What should happen (e.g., "returns tibble", "returns list")
#' @param cassette_name Name for the VCR cassette
#' @return A test_that() call
#' @examples
#' \dontrun{
#' generate_wrapper_test(
#'   fn_name = "ct_hazard",
#'   test_inputs = list(dtxsid = "DTXSID7020182"),
#'   expected_behavior = "returns_tibble",
#'   cassette_name = "ct_hazard_single"
#' )
#' }
generate_wrapper_test <- function(fn_name,
                                   test_inputs,
                                   expected_behavior = c("returns_tibble", "returns_list", "returns_character"),
                                   cassette_name = NULL) {

  expected_behavior <- match.arg(expected_behavior)

  if (is.null(cassette_name)) {
    cassette_name <- paste0(fn_name, "_", paste(names(test_inputs), collapse = "_"))
  }

  # Build the function call
  fn_call <- rlang::call2(fn_name, !!!test_inputs)

  # Determine expectations based on behavior
  expectations <- switch(
    expected_behavior,
    returns_tibble = quote({
      expect_s3_class(result, "tbl_df")
      expect_true(ncol(result) > 0)
    }),
    returns_list = quote({
      expect_type(result, "list")
      expect_true(length(result) > 0)
    }),
    returns_character = quote({
      expect_type(result, "character")
      expect_true(length(result) > 0)
    })
  )

  # Return the test
  bquote(
    test_that(.(paste(fn_name, "works with valid input")), {
      vcr::use_cassette(.(cassette_name), {
        result <- .(fn_call)
        .(expectations)
      })
    })
  )
}

#' Generate batch test for wrapper function
#'
#' @param fn_name Function name
#' @param batch_inputs Vector or list of inputs to batch
#' @param param_name Name of the parameter to batch (e.g., "dtxsid")
#' @param cassette_name VCR cassette name
generate_batch_test <- function(fn_name, batch_inputs, param_name = "dtxsid", cassette_name = NULL) {

  if (is.null(cassette_name)) {
    cassette_name <- paste0(fn_name, "_batch")
  }

  test_call <- rlang::call2(fn_name, !!rlang::sym(param_name) := batch_inputs)

  bquote(
    test_that(.(paste(fn_name, "handles batch requests")), {
      vcr::use_cassette(.(cassette_name), {
        result <- .(test_call)
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
      })
    })
  )
}

#' Generate error handling test
#'
#' @param fn_name Function name
#' @param bad_input Invalid input to test
#' @param param_name Parameter name for the bad input
generate_error_test <- function(fn_name, bad_input, param_name = "dtxsid") {

  test_call <- rlang::call2(fn_name, !!rlang::sym(param_name) := bad_input)

  bquote(
    test_that(.(paste(fn_name, "handles invalid input gracefully")), {
      vcr::use_cassette(.(paste0(fn_name, "_error")), {
        expect_warning(result <- .(test_call))
        expect_true(is.null(result) || nrow(result) == 0)
      })
    })
  )
}

#' Create a complete test file for a wrapper function
#'
#' @param fn_name Function name
#' @param valid_input Valid test input
#' @param batch_input Batch test inputs
#' @param invalid_input Invalid test input
#' @param output_file Where to write the test file (NULL for stdout)
#' @export
create_wrapper_test_file <- function(fn_name,
                                      valid_input,
                                      batch_input = NULL,
                                      invalid_input = NULL,
                                      output_file = NULL) {

  # Generate file header
  header <- paste0(
    "# Tests for ", fn_name, "\n",
    "# Generated using helper-test-generator.R\n\n"
  )

  # Generate tests
  tests <- list()

  # Basic functionality test
  tests[[1]] <- generate_wrapper_test(
    fn_name = fn_name,
    test_inputs = valid_input,
    expected_behavior = "returns_tibble"
  )

  # Batch test if provided
  if (!is.null(batch_input)) {
    tests[[2]] <- generate_batch_test(
      fn_name = fn_name,
      batch_inputs = batch_input,
      param_name = names(valid_input)[1]
    )
  }

  # Error test if provided
  if (!is.null(invalid_input)) {
    tests[[3]] <- generate_error_test(
      fn_name = fn_name,
      bad_input = invalid_input,
      param_name = names(valid_input)[1]
    )
  }

  # Convert tests to text
  test_code <- paste(
    header,
    paste(sapply(tests, function(t) {
      if (!is.null(t)) {
        paste(deparse(t), collapse = "\n")
      }
    }), collapse = "\n\n"),
    sep = "\n"
  )

  if (is.null(output_file)) {
    cat(test_code)
  } else {
    writeLines(test_code, output_file)
  }

  invisible(test_code)
}

#' Generate tests for all ct_ functions
#'
#' @param output_dir Directory to write test files
#' @export
generate_all_ct_tests <- function(output_dir = "tests/testthat") {

  # Define standard test cases for different function types
  standard_dtxsid_test <- list(
    valid = list(dtxsid = "DTXSID7020182"),
    batch = c("DTXSID7020182", "DTXSID5032381"),
    invalid = "INVALID_ID"
  )

  # Get all ct_ functions
  ct_functions <- ls("package:ComptoxR", pattern = "^ct_")
  ct_functions <- ct_functions[!ct_functions %in% c("ct_api_key", "ct_server")]

  message("Found ", length(ct_functions), " ct_ functions to test")
  message("Generating test files...")

  for (fn in ct_functions) {
    output_file <- file.path(output_dir, paste0("test-", fn, ".R"))

    if (!file.exists(output_file)) {
      create_wrapper_test_file(
        fn_name = fn,
        valid_input = standard_dtxsid_test$valid,
        batch_input = standard_dtxsid_test$batch,
        invalid_input = standard_dtxsid_test$invalid,
        output_file = output_file
      )
      message("✓ Created ", output_file)
    } else {
      message("✗ Skipped ", output_file, " (already exists)")
    }
  }

  invisible(ct_functions)
}

# ==============================================================================
# Schema-Driven Test Discovery
# ==============================================================================

#' Discover wrapper functions from R source files
#'
#' Scans the R/ directory for wrapper functions (ct_* and chemi_*) and extracts
#' their parameter signatures to infer appropriate test case templates.
#'
#' @param r_dir Path to the R/ directory containing wrapper functions.
#' @param exclude_patterns Character vector of function name patterns to exclude.
#' @return A tibble with columns: fn_name, file_path, first_param, param_type
#' @export
discover_wrapper_functions <- function(
    r_dir = NULL,
    exclude_patterns = c("^ct_api_key$", "^ct_server$", "^chemi_server$", "^ct_schema$", "^chemi_schema$")
) {
  if (is.null(r_dir)) {
    r_dir <- if (requireNamespace("here", quietly = TRUE)) {
      here::here("R")
    } else {
      "R"
    }
  }

  if (!dir.exists(r_dir)) {
    stop("R directory does not exist: ", r_dir)
  }

  # Find all ct_* and chemi_* R files
  r_files <- list.files(
    path = r_dir,
    pattern = "^(ct_|chemi_).*\\.R$",
    full.names = TRUE
  )

  if (length(r_files) == 0) {
    warning("No wrapper function files found in ", r_dir)
    return(tibble::tibble(
      fn_name = character(),
      file_path = character(),
      first_param = character(),
      param_type = character()
    ))
  }

  # Parse each file to extract function name and first parameter
  fn_data <- lapply(r_files, function(file_path) {
    tryCatch({
      lines <- readLines(file_path, warn = FALSE)
      text <- paste(lines, collapse = "\n")

      # Extract function name using regex
      # Pattern matches: fn_name <- function(
      fn_match <- regmatches(
        text,
        regexpr("(ct_|chemi_)[a-z0-9_]+(?=\\s*(<-|=)\\s*function)", text, perl = TRUE)
      )

      if (length(fn_match) == 0 || fn_match == "") {
        return(NULL)
      }

      fn_name <- fn_match[1]

      # Extract first parameter name
      # Pattern matches: function(param_name, or function(param_name = or function(param_name)
      param_pattern <- paste0(fn_name, "\\s*(<-|=)\\s*function\\s*\\(\\s*([a-z_][a-z0-9_]*)")
      param_match <- regmatches(text, regexec(param_pattern, text, perl = TRUE))[[1]]

      first_param <- if (length(param_match) >= 3) param_match[3] else NA_character_

      list(
        fn_name = fn_name,
        file_path = file_path,
        first_param = first_param
      )
    }, error = function(e) NULL)
  })

  # Remove NULLs and convert to tibble
  fn_data <- Filter(Negate(is.null), fn_data)

  if (length(fn_data) == 0) {
    return(tibble::tibble(
      fn_name = character(),
      file_path = character(),
      first_param = character(),
      param_type = character()
    ))
  }

  result <- tibble::tibble(
    fn_name = vapply(fn_data, `[[`, character(1), "fn_name"),
    file_path = vapply(fn_data, `[[`, character(1), "file_path"),
    first_param = vapply(fn_data, function(x) x$first_param %||% NA_character_, character(1))
  )

  # Apply exclusion patterns
  for (pattern in exclude_patterns) {
    result <- result[!grepl(pattern, result$fn_name), ]
  }

  # Infer parameter type from first parameter name
  result$param_type <- vapply(result$first_param, function(param) {
    if (is.na(param)) return("unknown")
    param <- tolower(param)
    if (grepl("dtxsid|query", param)) return("dtxsid")
    if (grepl("cas", param)) return("cas")
    if (grepl("smiles", param)) return("smiles")
    if (grepl("list|listname", param)) return("list_name")
    if (grepl("formula", param)) return("formula")
    if (grepl("inchi", param)) return("inchikey")
    "dtxsid"  # Default to dtxsid for unknown parameters
  }, character(1))

  result
}

#' Get functions that are missing tests
#'
#' Compares discovered wrapper functions against existing test files to identify
#' which functions need tests to be generated.
#'
#' @param r_dir Path to R/ directory with wrapper functions.
#' @param test_dir Path to tests/testthat directory.
#' @param exclude_patterns Patterns to exclude from function discovery.
#' @return A tibble of wrapper functions that don't have corresponding test files.
#' @export
get_untested_functions <- function(
    r_dir = NULL,
    test_dir = NULL,
    exclude_patterns = c("^ct_api_key$", "^ct_server$", "^chemi_server$", "^ct_schema$", "^chemi_schema$")
) {
  if (is.null(test_dir)) {
    test_dir <- if (requireNamespace("here", quietly = TRUE)) {
      here::here("tests", "testthat")
    } else {
      "tests/testthat"
    }
  }

  # Discover all wrapper functions
  all_fns <- discover_wrapper_functions(r_dir = r_dir, exclude_patterns = exclude_patterns)

  if (nrow(all_fns) == 0) {
    return(all_fns)
  }

  # Find existing test files
  existing_tests <- list.files(
    path = test_dir,
    pattern = "^test-.*\\.R$",
    full.names = FALSE
  )

  # Extract function names from test file names (test-fn_name.R -> fn_name)
  tested_fns <- gsub("^test-|\\.R$", "", existing_tests)

  # Filter to functions without tests
  all_fns[!all_fns$fn_name %in% tested_fns, ]
}

#' Get test case template by parameter type
#'
#' Returns the appropriate test case template (valid input, batch input, invalid input)
#' based on the parameter type inferred from the function signature.
#'
#' @param param_type Character string: one of "dtxsid", "cas", "smiles", "list_name",
#'   "formula", "inchikey", or "unknown".
#' @return A list with elements: valid (named list), batch (character vector or NULL),
#'   invalid (character string).
#' @export
get_test_case_by_param_type <- function(param_type) {
  test_cases <- list(
    dtxsid = list(
      valid = list(query = "DTXSID7020182"),
      batch = c("DTXSID7020182", "DTXSID5032381", "DTXSID8024291"),
      invalid = "INVALID_DTXSID"
    ),
    cas = list(
      valid = list(cas = "50-00-0"),
      batch = c("50-00-0", "108-88-3", "71-43-2"),
      invalid = "INVALID-CAS"
    ),
    smiles = list(
      valid = list(smiles = "C=O"),
      batch = c("C=O", "c1ccccc1", "CCO"),
      invalid = "INVALID_SMILES"
    ),
    list_name = list(
      valid = list(listname = "PRODWATER"),
      batch = NULL,
      invalid = "NONEXISTENT_LIST"
    ),
    formula = list(
      valid = list(formula = "C2H6O"),
      batch = NULL,
      invalid = "INVALID_FORMULA"
    ),
    inchikey = list(
      valid = list(inchikey = "LFQSCWFLJHTTHZ-UHFFFAOYSA-N"),
      batch = NULL,
      invalid = "INVALID_INCHIKEY"
    ),
    unknown = list(
      valid = list(query = "DTXSID7020182"),
      batch = c("DTXSID7020182", "DTXSID5032381"),
      invalid = "INVALID_INPUT"
    )
  )

  test_cases[[param_type]] %||% test_cases[["unknown"]]
}

#' Generate tests for schema-discovered functions
#'
#' Discovers wrapper functions from the R/ directory, identifies those without
#' existing tests, and generates test files using appropriate test case templates
#' inferred from the function parameter types.
#'
#' This function integrates schema-driven discovery with the existing test
#' generation infrastructure, automatically determining the right test cases
#' for each function based on its first parameter name.
#'
#' @param r_dir Path to R/ directory with wrapper functions.
#' @param test_dir Path to tests/testthat directory for output.
#' @param overwrite If TRUE, overwrite existing test files.
#' @param dry_run If TRUE, only report what would be generated without creating files.
#' @return A list with elements: created, skipped, failed (character vectors of function names).
#' @export
#' @examples
#' \dontrun{
#' # See what tests would be generated
#' generate_schema_discovered_tests(dry_run = TRUE)
#'
#' # Generate tests for all untested functions
#' result <- generate_schema_discovered_tests()
#'
#' # Force regenerate all tests
#' result <- generate_schema_discovered_tests(overwrite = TRUE)
#' }
generate_schema_discovered_tests <- function(
    r_dir = NULL,
    test_dir = NULL,
    overwrite = FALSE,
    dry_run = FALSE
) {
  if (is.null(test_dir)) {
    test_dir <- if (requireNamespace("here", quietly = TRUE)) {
      here::here("tests", "testthat")
    } else {
      "tests/testthat"
    }
  }

  # Discover untested functions (or all functions if overwrite = TRUE)
  if (overwrite) {
    fns_to_test <- discover_wrapper_functions(r_dir = r_dir)
  } else {
    fns_to_test <- get_untested_functions(r_dir = r_dir, test_dir = test_dir)
  }

  if (nrow(fns_to_test) == 0) {
    message("All wrapper functions already have tests!")
    return(invisible(list(created = character(), skipped = character(), failed = character())))
  }

  cat("Discovered", nrow(fns_to_test), "functions to test:\n")
  for (i in seq_len(nrow(fns_to_test))) {
    cat("  -", fns_to_test$fn_name[i], "(", fns_to_test$param_type[i], ")\n")
  }

  if (dry_run) {
    cat("\nDry run - no files created.\n")
    return(invisible(list(
      created = character(),
      skipped = character(),
      failed = character(),
      would_create = fns_to_test$fn_name
    )))
  }

  results <- list(
    created = character(),
    skipped = character(),
    failed = character()
  )

  for (i in seq_len(nrow(fns_to_test))) {
    fn_name <- fns_to_test$fn_name[i]
    param_type <- fns_to_test$param_type[i]
    test_file <- file.path(test_dir, paste0("test-", fn_name, ".R"))

    # Skip if file exists and overwrite is FALSE
    if (file.exists(test_file) && !overwrite) {
      cat("⊗ Skipped", fn_name, "(file exists)\n")
      results$skipped <- c(results$skipped, fn_name)
      next
    }

    # Get appropriate test case template
    test_case <- get_test_case_by_param_type(param_type)

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
      cat("✗ Failed", fn_name, ":", conditionMessage(e), "\n")
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

  invisible(results)
}

# Null-coalesce operator (if not already defined)
`%||%` <- function(x, y) if (is.null(x)) y else x
