# Enhanced Test Generator for ComptoxR
#
# This generator creates tests based on actual function signatures and return types
# extracted from the source code and documentation.

source("tests/testthat/tools/helper-function-metadata.R")

#' Standard test inputs for different parameter types
#'
#' These are organized by parameter name/type rather than assuming all functions
#' use the same parameter
get_standard_test_inputs <- function() {
  list(
    # DTXSID-based queries
    query_dtxsid = list(
      single = "DTXSID7020182",  # Bisphenol A
      batch = c("DTXSID7020182", "DTXSID5032381", "DTXSID8024291"),
      invalid = "INVALID_DTXSID_12345"
    ),

    # List name queries
    list_name = list(
      single = "PRODWATER",
      batch = c("PRODWATER", "CWA311HS"),
      invalid = "NONEXISTENT_LIST_XYZ"
    ),

    # DTXSID parameter (not query)
    dtxsid = list(
      single = "DTXSID7020182",
      batch = c("DTXSID7020182", "DTXSID5032381"),
      invalid = "INVALID_DTXSID"
    ),

    # Chemical name queries
    chemicals = list(
      single = "benzene",
      batch = c("benzene", "toluene", "xylene"),
      invalid = "INVALID_CHEMICAL_NAME_XYZ_999"
    ),

    # CAS RN queries
    casrn = list(
      single = "50-00-0",  # Formaldehyde
      batch = c("50-00-0", "71-43-2", "108-88-3"),
      invalid = "999-99-9"
    ),

    # Formula queries
    formula = list(
      single = "C6H6",
      batch = c("C6H6", "C7H8"),
      invalid = "INVALID_FORMULA"
    ),

    # SMILES queries
    smiles = list(
      single = "c1ccccc1",  # Benzene
      batch = c("c1ccccc1", "CC(C)O"),
      invalid = "INVALID_SMILES_XYZ"
    )
  )
}

#' Determine which test input to use based on parameter name
#'
#' @param param_name Parameter name from function signature
#' @param metadata Function metadata
#' @return Key for test inputs list
determine_test_input_type <- function(param_name, metadata) {
  # Check parameter name
  if (param_name == "query") {
    # Look at endpoint to determine query type
    if (!is.null(metadata$generic_request)) {
      endpoint <- metadata$generic_request$endpoint
      if (grepl("list", endpoint, ignore.case = TRUE)) {
        return("list_name")
      }
    }
    return("query_dtxsid")
  }

  # Direct parameter name matches
  param_map <- list(
    list_name = "list_name",
    dtxsid = "dtxsid",
    chemicals = "chemicals",
    casrn = "casrn",
    formula = "formula",
    smiles = "smiles"
  )

  if (param_name %in% names(param_map)) {
    return(param_map[[param_name]])
  }

  # Default
  "query_dtxsid"
}

#' Generate expectations based on return type
#'
#' @param return_type Return type from metadata
#' @return R code for expectations
generate_return_expectations <- function(return_type) {
  switch(
    return_type,

    tibble = quote({
      expect_s3_class(result, "tbl_df")
      expect_true(ncol(result) > 0 || nrow(result) == 0)
    }),

    character = quote({
      expect_type(result, "character")
      # Allow empty character vector for no results
      expect_true(is.character(result))
    }),

    list = quote({
      expect_type(result, "list")
      # Lists can be empty if no results
      expect_true(is.list(result))
    }),

    image = quote({
      # Image data can be raw bytes or magick object
      expect_true(
        inherits(result, "magick-image") ||
        is.raw(result) ||
        is.character(result)  # May return file path
      )
    }),

    logical = quote({
      expect_type(result, "logical")
      expect_true(length(result) > 0)
    }),

    numeric = quote({
      expect_type(result, "double")
      expect_true(is.numeric(result))
    }),

    # Unknown/default - be permissive
    quote({
      expect_true(!is.null(result))
    })
  )
}

#' Generate a basic functionality test
#'
#' @param metadata Function metadata
#' @param test_inputs Standard test inputs
#' @return Test code
generate_basic_test <- function(metadata, test_inputs) {
  fn_name <- metadata$name
  params <- metadata$function_def$params

  # Determine primary parameter
  primary_param <- if (length(params) > 0) {
    names(params)[1]
  } else {
    NULL
  }

  # Generate test based on whether function has parameters
  if (is.null(primary_param)) {
    # No parameters - just call the function
    test_call <- rlang::call2(fn_name)
    cassette_name <- paste0(fn_name, "_basic")
    test_name <- paste(fn_name, "works without parameters")
  } else {
    # Use appropriate test input
    input_type <- determine_test_input_type(primary_param, metadata)
    input_data <- test_inputs[[input_type]]$single

    # Build function call
    test_args <- list()
    test_args[[primary_param]] <- input_data

    test_call <- rlang::call2(fn_name, !!!test_args)
    cassette_name <- paste0(fn_name, "_single")
    test_name <- paste(fn_name, "works with single input")
  }

  # Generate expectations
  expectations <- generate_return_expectations(metadata$return_type$type)

  # Build test
  bquote(
    test_that(.(test_name), {
      vcr::use_cassette(.(cassette_name), {
        result <- .(test_call)
        .(expectations)
      })
    })
  )
}

#' Generate batch test if applicable
#'
#' @param metadata Function metadata
#' @param test_inputs Standard test inputs
#' @return Test code or NULL
generate_batch_test <- function(metadata, test_inputs) {
  fn_name <- metadata$name
  params <- metadata$function_def$params

  if (length(params) == 0) {
    return(NULL)
  }

  primary_param <- names(params)[1]

  # Determine if function likely supports batching
  # Functions with batch_limit > 1 or using POST typically support batching
  supports_batch <- FALSE
  if (!is.null(metadata$generic_request)) {
    batch_limit <- metadata$generic_request$batch_limit
    method <- metadata$generic_request$method
    supports_batch <- (is.null(batch_limit) || batch_limit != "0") &&
                      (is.null(method) || method == "POST")
  }

  if (!supports_batch) {
    return(NULL)
  }

  # Get batch input
  input_type <- determine_test_input_type(primary_param, metadata)
  batch_input <- test_inputs[[input_type]]$batch

  # Build function call
  test_args <- list()
  test_args[[primary_param]] <- batch_input

  test_call <- rlang::call2(fn_name, !!!test_args)
  cassette_name <- paste0(fn_name, "_batch")

  # For batch tests, we expect results (possibly empty if no data)
  return_type <- metadata$return_type$type

  # Adjust expectations for batch
  if (return_type == "tibble") {
    expectations <- quote({
      expect_s3_class(result, "tbl_df")
      # Batch may return more rows or be empty
      expect_true(is.data.frame(result))
    })
  } else if (return_type == "character") {
    expectations <- quote({
      expect_type(result, "character")
      # Batch may return multiple values
      expect_true(is.character(result))
    })
  } else {
    expectations <- generate_return_expectations(return_type)
  }

  bquote(
    test_that(.(paste(fn_name, "handles batch requests")), {
      vcr::use_cassette(.(cassette_name), {
        result <- .(test_call)
        .(expectations)
      })
    })
  )
}

#' Generate error handling test
#'
#' @param metadata Function metadata
#' @param test_inputs Standard test inputs
#' @return Test code or NULL
generate_error_test <- function(metadata, test_inputs) {
  fn_name <- metadata$name
  params <- metadata$function_def$params

  if (length(params) == 0) {
    return(NULL)
  }

  primary_param <- names(params)[1]

  # Get invalid input
  input_type <- determine_test_input_type(primary_param, metadata)
  invalid_input <- test_inputs[[input_type]]$invalid

  # Build function call
  test_args <- list()
  test_args[[primary_param]] <- invalid_input

  test_call <- rlang::call2(fn_name, !!!test_args)
  cassette_name <- paste0(fn_name, "_error")

  bquote(
    test_that(.(paste(fn_name, "handles invalid input gracefully")), {
      vcr::use_cassette(.(cassette_name), {
        # Should either warn or return NULL/empty result
        result <- suppressWarnings(.(test_call))
        expect_true(
          is.null(result) ||
          (is.data.frame(result) && nrow(result) == 0) ||
          (is.character(result) && length(result) == 0) ||
          (is.list(result) && length(result) == 0)
        )
      })
    })
  )
}

#' Generate test from example if available
#'
#' @param metadata Function metadata
#' @return Test code or NULL
generate_example_test <- function(metadata) {
  if (length(metadata$examples) == 0) {
    return(NULL)
  }

  fn_name <- metadata$name

  # Use first example
  example_code <- metadata$examples[1]

  # Try to parse the example
  tryCatch({
    # Simple validation that it looks like a function call
    if (!grepl(fn_name, example_code)) {
      return(NULL)
    }

    # Create test using the example
    cassette_name <- paste0(fn_name, "_example")

    # Parse example code
    example_expr <- parse(text = example_code)[[1]]

    bquote(
      test_that(.(paste(fn_name, "works with documented example")), {
        vcr::use_cassette(.(cassette_name), {
          # Run the example - it should not error
          result <- .(example_expr)
          expect_true(!is.null(result))
        })
      })
    )
  }, error = function(e) {
    NULL
  })
}

#' Create complete test file for a function using metadata
#'
#' @param metadata Function metadata from extract_function_metadata
#' @param output_file Where to write the test file
#' @param test_inputs Standard test inputs (optional)
create_metadata_based_test_file <- function(metadata,
                                             output_file = NULL,
                                             test_inputs = NULL) {

  if (is.null(test_inputs)) {
    test_inputs <- get_standard_test_inputs()
  }

  fn_name <- metadata$name

  # Generate file header
  header <- paste0(
    "# Tests for ", fn_name, "\n",
    "# Generated using metadata-based test generator\n",
    "# Return type: ", metadata$return_type$type, "\n",
    "# ", metadata$return_type$description, "\n\n"
  )

  # Generate tests
  tests <- list()

  # 1. Basic functionality test
  tests[[1]] <- generate_basic_test(metadata, test_inputs)

  # 2. Example-based test (if available)
  example_test <- generate_example_test(metadata)
  if (!is.null(example_test)) {
    tests[[length(tests) + 1]] <- example_test
  }

  # 3. Batch test (if applicable)
  batch_test <- generate_batch_test(metadata, test_inputs)
  if (!is.null(batch_test)) {
    tests[[length(tests) + 1]] <- batch_test
  }

  # 4. Error handling test
  error_test <- generate_error_test(metadata, test_inputs)
  if (!is.null(error_test)) {
    tests[[length(tests) + 1]] <- error_test
  }

  # Convert tests to text
  test_code <- paste(
    header,
    paste(sapply(tests, function(t) {
      if (!is.null(t)) {
        paste(deparse(t, width.cutoff = 80), collapse = "\n")
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
