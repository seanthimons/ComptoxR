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
