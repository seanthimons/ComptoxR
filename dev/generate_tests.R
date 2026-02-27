# Test Generator - Metadata-Aware Test Generation for ComptoxR
#
# This script generates unit tests for API wrapper functions by reading actual
# function signatures and extracting the tidy flag from function bodies.
#
# Addresses TGEN-01 through TGEN-05:
# - TGEN-01: Read parameter names and types from function signatures
# - TGEN-02: Read tidy flag from function bodies
# - TGEN-03: Handle functions with no parameters (static endpoints)
# - TGEN-04: Handle functions with path_params
# - TGEN-05: Use unique cassette names per variant

library(glue)
library(purrr)
library(stringr)
library(cli)

#' Extract function formals (parameters) from R source file
#'
#' @description
#' Reads an R source file and extracts the formal parameters of a named function.
#' Uses parse() for robust extraction, with regex-based fallback for unparseable files.
#' Filters out framework parameters (tidy, verbose, ...).
#'
#' @param file_path Path to R source file
#' @param function_name Name of function to extract formals from
#' @return Named list of formal parameters, or NULL if function not found
#' @export
extract_function_formals <- function(file_path, function_name) {
  tryCatch({
    # Parse the file
    expr <- parse(file = file_path)

    # Find function assignment
    for (e in expr) {
      if (is.call(e) && identical(e[[1]], as.name("<-"))) {
        lhs <- e[[2]]
        rhs <- e[[3]]

        if (identical(lhs, as.name(function_name)) && is.call(rhs)) {
          # Extract formals
          if (identical(rhs[[1]], as.name("function"))) {
            params <- formals(eval(rhs))

            # Filter out framework parameters
            framework_params <- c("tidy", "verbose", "...")
            params <- params[!names(params) %in% framework_params]

            return(params)
          }
        }
      }
    }

    NULL
  }, error = function(e) {
    # Fallback: regex-based extraction for unparseable files
    cli::cli_alert_warning("Parse failed for {file_path}, using regex fallback")
    extract_formals_regex(file_path, function_name)
  })
}

#' Regex-based fallback for extracting function parameters
#' @noRd
extract_formals_regex <- function(file_path, function_name) {
  lines <- readLines(file_path, warn = FALSE)

  # Find function definition line
  fn_pattern <- paste0("^", function_name, "\\s*<-\\s*function\\s*\\(")
  fn_line_idx <- grep(fn_pattern, lines)

  if (length(fn_line_idx) == 0) return(NULL)

  # Extract signature (may span multiple lines until closing paren)
  sig_start <- fn_line_idx[1]
  sig_lines <- lines[sig_start]

  # Find closing paren (handle multi-line signatures)
  open_count <- str_count(sig_lines, "\\(")
  close_count <- str_count(sig_lines, "\\)")

  line_idx <- sig_start
  while (open_count > close_count && line_idx < length(lines)) {
    line_idx <- line_idx + 1
    sig_lines <- paste(sig_lines, lines[line_idx])
    open_count <- open_count + str_count(lines[line_idx], "\\(")
    close_count <- close_count + str_count(lines[line_idx], "\\)")
  }

  # Extract parameter text between function( and )
  param_text <- str_extract(sig_lines, "function\\s*\\(([^)]+)\\)", group = 1)
  if (is.na(param_text)) return(NULL)

  # Split by comma, extract parameter names (ignore defaults)
  params <- str_split(param_text, ",")[[1]]
  params <- str_trim(params)
  param_names <- str_extract(params, "^[a-zA-Z_][a-zA-Z0-9_]*")
  param_names <- param_names[!is.na(param_names)]

  # Filter out framework parameters
  framework_params <- c("tidy", "verbose", "...")
  param_names <- param_names[!param_names %in% framework_params]

  # Return as named list with NULL defaults (we don't parse defaults in regex mode)
  result <- as.list(rep(list(NULL), length(param_names)))
  names(result) <- param_names
  result
}

#' Extract tidy flag from function body
#'
#' @description
#' Reads function source and searches for tidy parameter in generic_request(),
#' generic_chemi_request(), or generic_cc_request() calls.
#'
#' Handles three cases:
#' 1. Explicit tidy = TRUE/FALSE in request call
#' 2. Pass-through: tidy = tidy (function forwards its own tidy parameter)
#' 3. Missing: defaults to TRUE
#'
#' @param file_path Path to R source file
#' @return Logical indicating tidy flag value (default TRUE)
#' @export
extract_tidy_flag <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)

  # Find lines with generic request calls
  request_patterns <- c(
    "generic_request\\(",
    "generic_chemi_request\\(",
    "generic_cc_request\\("
  )

  request_lines <- character(0)
  for (pattern in request_patterns) {
    matches <- grep(pattern, lines, value = TRUE)
    if (length(matches) > 0) {
      request_lines <- c(request_lines, matches)
    }
  }

  if (length(request_lines) == 0) {
    # No generic request call found - default to TRUE
    return(TRUE)
  }

  # Search for explicit tidy = TRUE/FALSE
  for (line in request_lines) {
    # Look for explicit tidy = TRUE or tidy = FALSE
    if (grepl("tidy\\s*=\\s*TRUE", line, ignore.case = TRUE)) {
      return(TRUE)
    }
    if (grepl("tidy\\s*=\\s*FALSE", line, ignore.case = TRUE)) {
      return(FALSE)
    }
    # Look for pass-through: tidy = tidy
    if (grepl("tidy\\s*=\\s*tidy", line)) {
      # Check function signature for tidy default
      # If function has tidy parameter, need to check its default
      # For now, assume TRUE (most common case)
      return(TRUE)
    }
  }

  # Default to TRUE if tidy param not found
  TRUE
}

#' Get appropriate test value for a parameter name
#'
#' @description
#' Maps parameter names to appropriate test values based on:
#' 1. Priority 1: param_examples (from roxygen @examples) if provided
#' 2. Priority 2: Exact match in mapping table
#' 3. Priority 3: Pattern matching (numeric, boolean indicators)
#' 4. Priority 4: Canonical DTXSID fallback
#'
#' @param param_name Parameter name from function signature
#' @param param_examples Optional vector of example values from roxygen
#' @return Test value of appropriate type
#' @export
get_test_value_for_param <- function(param_name, param_examples = NULL) {
  # Priority 1: Use roxygen examples if available
  if (!is.null(param_examples) && length(param_examples) > 0) {
    return(param_examples[1])
  }

  # Priority 2: Exact match in mapping table
  mapping <- list(
    # Identifiers
    query = "DTXSID7020182",
    dtxsid = "DTXSID7020182",
    dtxcid = "DTXCID30182",
    casrn = "80-05-7",
    cas = "80-05-7",
    smiles = "c1ccccc1",
    inchi = "InChI=1S/C6H6/c1-2-4-6-5-3-1/h1-6H",
    inchikey = "UHOVQNZJYSORNB-UHFFFAOYSA-N",

    # Numeric parameters
    limit = 100L,
    offset = 0L,
    page = 1L,
    top = 10L,
    skip = 0L,
    count = 100L,
    size = 100L,
    start = 0L,
    end = 100L,

    # Chemical properties
    formula = "C15H14O",
    mass = 210.0,
    property_name = "MolWeight",

    # String parameters
    search_type = "equals",
    list_name = "PRODWATER",
    domain = "hazard",
    aeid = 42L,
    model = "RF",
    idType = "AnyId",

    # Path parameters
    medium = "water",
    study_id = "12345",
    study_type = "acute",

    # Boolean
    verbose = FALSE,
    extract_dtxsids = TRUE,
    coerce = FALSE,
    return_dtxsid = FALSE
  )

  # Check exact match
  if (param_name %in% names(mapping)) {
    return(mapping[[param_name]])
  }

  # Priority 3: Pattern matching
  if (grepl("limit|count|size|top", param_name, ignore.case = TRUE)) {
    return(100L)
  }
  if (grepl("offset|skip|start", param_name, ignore.case = TRUE)) {
    return(0L)
  }
  if (grepl("page", param_name, ignore.case = TRUE)) {
    return(1L)
  }
  if (grepl("verbose|extract|coerce|return", param_name, ignore.case = TRUE)) {
    return(FALSE)
  }

  # Priority 4: Canonical DTXSID fallback
  "DTXSID7020182"
}

#' Get batch test values for a parameter
#'
#' @description
#' Returns a vector of 2-3 test values for batch testing.
#'
#' @param param_name Parameter name from function signature
#' @return Character or numeric vector with 2-3 test values
#' @export
get_batch_test_values <- function(param_name) {
  single_val <- get_test_value_for_param(param_name)

  # For DTXSIDs, use canonical set
  if (is.character(single_val) && grepl("DTXSID", single_val)) {
    return(c("DTXSID7020182", "DTXSID3060245"))
  }

  # For DTXCIDs
  if (is.character(single_val) && grepl("DTXCID", single_val)) {
    return(c("DTXCID30182", "DTXCID2060245"))
  }

  # For SMILES
  if (param_name == "smiles") {
    return(c("c1ccccc1", "CC(C)O"))
  }

  # For CAS
  if (param_name %in% c("casrn", "cas")) {
    return(c("80-05-7", "67-64-1"))
  }

  # For formula
  if (param_name == "formula") {
    return(c("C15H14O", "C6H6"))
  }

  # For list names
  if (param_name == "list_name") {
    return(c("PRODWATER", "CWA311HS"))
  }

  # For integers, return range
  if (is.integer(single_val)) {
    return(c(single_val, single_val + 10L))
  }

  # For numeric, return range
  if (is.numeric(single_val)) {
    return(c(single_val, single_val + 10))
  }

  # Default: duplicate single value
  c(single_val, single_val)
}

#' Generate test file for a function
#'
#' @description
#' Generates a complete test file with three test variants:
#' - single: one valid input with VCR cassette
#' - batch: 2-3 inputs with VCR cassette (skipped for static endpoints)
#' - error: missing required params, no cassette
#'
#' @param function_name Name of function to generate tests for
#' @param function_file Path to R source file containing function
#' @param output_dir Path to tests/testthat directory
#' @return Path to generated test file
#' @export
generate_test_file <- function(function_name, function_file, output_dir = "tests/testthat") {
  # Extract function metadata
  params <- extract_function_formals(function_file, function_name)
  tidy_flag <- extract_tidy_flag(function_file)

  # Determine return assertion based on tidy flag
  return_assertion <- if (tidy_flag) {
    'expect_s3_class(result, "tbl_df")'
  } else {
    'expect_type(result, "list")'
  }

  # Handle different function types
  if (length(params) == 0) {
    # Static endpoint (no parameters)
    single_call <- glue("{function_name}()")
    batch_test <- NULL  # Skip batch test for static endpoints

    error_test <- glue('
test_that("{function_name} handles invalid arguments", {{
  # Static endpoint - no required parameters
  # Test with invalid argument
  expect_error({function_name}(invalid_arg = "test"))
}})')

  } else {
    # Has parameters
    param_names <- names(params)
    primary_param <- param_names[1]

    # Get test values
    single_val <- get_test_value_for_param(primary_param)
    batch_vals <- get_batch_test_values(primary_param)

    # Build function calls
    if (is.character(single_val)) {
      single_call <- glue('{function_name}({primary_param} = "{single_val}")')
      batch_val_str <- paste0('"', batch_vals, '"', collapse = ", ")
      batch_call <- glue('{function_name}({primary_param} = c({batch_val_str}))')
    } else {
      single_call <- glue('{function_name}({primary_param} = {single_val})')
      batch_val_str <- paste(batch_vals, collapse = ", ")
      batch_call <- glue('{function_name}({primary_param} = c({batch_val_str}))')
    }

    # Batch test
    batch_test <- glue('
test_that("{function_name} handles batch requests", {{
  vcr::use_cassette("{function_name}_batch", {{
    result <- {batch_call}
    {return_assertion}
  }})
}})')

    # Error test
    error_test <- glue('
test_that("{function_name} handles errors gracefully", {{
  expect_error({function_name}())
}})')
  }

  # Build test file content
  test_content <- glue('
# Tests for {function_name}
# Generated using metadata-based test generator

test_that("{function_name} works with single input", {{
  vcr::use_cassette("{function_name}_single", {{
    result <- {single_call}
    {return_assertion}
  }})
}})
')

  # Add batch test if applicable
  if (!is.null(batch_test)) {
    test_content <- paste0(test_content, "\n", batch_test)
  }

  # Add error test
  test_content <- paste0(test_content, "\n", error_test)

  # Write to file
  test_file <- file.path(output_dir, paste0("test-", function_name, ".R"))
  writeLines(test_content, test_file)

  cli::cli_alert_success("Generated {test_file}")
  invisible(test_file)
}

#' Main entry point: Scan R/ and generate tests for gaps
#'
#' @description
#' When sourced as a script, scans R/ for ct_*, chemi_*, cc_* functions,
#' detects which ones lack test files, and generates tests for them.
#'
#' @param r_dir Path to R/ directory
#' @param test_dir Path to tests/testthat/ directory
#' @param force Regenerate all tests even if they exist
#' @export
generate_all_tests <- function(r_dir = "R", test_dir = "tests/testthat", force = FALSE) {
  # Find all API wrapper function files
  function_files <- list.files(
    r_dir,
    pattern = "^(ct_|chemi_|cc_)[^.]+\\.R$",
    full.names = TRUE
  )

  cli::cli_h1("Test Generation Summary")
  cli::cli_alert_info("Found {length(function_files)} API wrapper files")

  generated_count <- 0
  skipped_count <- 0

  for (file in function_files) {
    # Extract function name from filename
    function_name <- tools::file_path_sans_ext(basename(file))

    # Check if test file already exists
    test_file <- file.path(test_dir, paste0("test-", function_name, ".R"))

    if (file.exists(test_file) && !force) {
      skipped_count <- skipped_count + 1
      next
    }

    # Generate test
    tryCatch({
      generate_test_file(function_name, file, test_dir)
      generated_count <- generated_count + 1
    }, error = function(e) {
      cli::cli_alert_danger("Failed to generate test for {function_name}: {e$message}")
    })
  }

  cli::cli_alert_success("Generated {generated_count} test files")
  cli::cli_alert_info("Skipped {skipped_count} existing test files")

  invisible(list(
    generated = generated_count,
    skipped = skipped_count,
    total = length(function_files)
  ))
}

# If sourced as a script (not in a test), run the generator
if (!exists("testthat_test_that_env", envir = parent.frame())) {
  # Only run if not in a test context
  if (interactive()) {
    cli::cli_alert_info("Source this file and run generate_all_tests() to generate tests")
  }
}
