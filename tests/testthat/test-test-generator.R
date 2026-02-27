# Unit tests for test generator (dev/generate_tests.R)
# Tests all 5 TGEN requirements

# Source the test generator
source("../../dev/generate_tests.R")

# Save project root for tests that use temp directories
PROJECT_ROOT <- normalizePath(file.path(getwd(), "..", ".."), winslash = "/")

# TGEN-01: Parameter extraction and type mapping ----

test_that("extract_function_formals extracts parameters from ct_hazard", {
  # ct_hazard has one parameter: query
  formals <- extract_function_formals("../../R/ct_hazard.R", "ct_hazard")

  expect_type(formals, "list")
  expect_true("query" %in% names(formals))
  # tidy and verbose should be filtered out
  expect_false("tidy" %in% names(formals))
  expect_false("verbose" %in% names(formals))
})

test_that("extract_function_formals extracts parameters from ct_list", {
  # ct_list has two parameters: list_name, extract_dtxsids
  formals <- extract_function_formals("../../R/ct_list.R", "ct_list")

  expect_type(formals, "list")
  expect_true("list_name" %in% names(formals))
  expect_true("extract_dtxsids" %in% names(formals))
})

test_that("extract_function_formals handles static endpoints (ct_lists_all)", {
  # ct_lists_all has parameters but they're all optional (return_dtxsid, coerce)
  formals <- extract_function_formals("../../R/ct_lists_all.R", "ct_lists_all")

  expect_type(formals, "list")
  # Should extract parameters even if they have defaults
  expect_true("return_dtxsid" %in% names(formals) || "coerce" %in% names(formals))
})

test_that("get_test_value_for_param returns correct types", {
  # Test DTXSID
  expect_equal(get_test_value_for_param("dtxsid"), "DTXSID7020182")
  expect_equal(get_test_value_for_param("query"), "DTXSID7020182")

  # Test DTXCID
  expect_equal(get_test_value_for_param("dtxcid"), "DTXCID30182")

  # Test integers
  expect_equal(get_test_value_for_param("limit"), 100L)
  expect_type(get_test_value_for_param("limit"), "integer")

  # Test formula
  expect_equal(get_test_value_for_param("formula"), "C15H14O")
  expect_type(get_test_value_for_param("formula"), "character")

  # Test CAS
  expect_equal(get_test_value_for_param("casrn"), "80-05-7")
  expect_equal(get_test_value_for_param("cas"), "80-05-7")

  # Test SMILES
  expect_equal(get_test_value_for_param("smiles"), "c1ccccc1")

  # Test list name
  expect_equal(get_test_value_for_param("list_name"), "PRODWATER")

  # Test boolean
  expect_equal(get_test_value_for_param("verbose"), FALSE)
})

test_that("get_test_value_for_param uses pattern matching for unknowns", {
  # Pattern matching for limit-like params
  expect_equal(get_test_value_for_param("result_limit"), 100L)
  expect_equal(get_test_value_for_param("max_count"), 100L)

  # Pattern matching for offset-like params
  expect_equal(get_test_value_for_param("start_offset"), 0L)
  expect_equal(get_test_value_for_param("skip_rows"), 0L)

  # Pattern matching for page
  expect_equal(get_test_value_for_param("page_number"), 1L)
})

test_that("get_test_value_for_param returns canonical DTXSID for unknown params", {
  # Unknown parameter should fall back to canonical DTXSID
  result <- get_test_value_for_param("unknown_param_xyz")
  expect_equal(result, "DTXSID7020182")
})

test_that("get_batch_test_values returns multiple values", {
  # DTXSID batch
  dtxsid_batch <- get_batch_test_values("dtxsid")
  expect_length(dtxsid_batch, 2)
  expect_true(all(grepl("DTXSID", dtxsid_batch)))

  # SMILES batch
  smiles_batch <- get_batch_test_values("smiles")
  expect_length(smiles_batch, 2)
  expect_equal(smiles_batch[1], "c1ccccc1")

  # CAS batch
  cas_batch <- get_batch_test_values("casrn")
  expect_length(cas_batch, 2)
  expect_equal(cas_batch[1], "80-05-7")

  # Integer batch
  limit_batch <- get_batch_test_values("limit")
  expect_length(limit_batch, 2)
  expect_type(limit_batch, "integer")
})

# TGEN-02: Tidy flag extraction ----

test_that("extract_tidy_flag detects tidy=TRUE functions", {
  # ct_hazard uses generic_request with default tidy (TRUE)
  tidy <- extract_tidy_flag("../../R/ct_hazard.R")
  expect_true(tidy)
})

test_that("extract_tidy_flag detects tidy=FALSE functions", {
  # ct_list explicitly sets tidy=FALSE
  tidy <- extract_tidy_flag("../../R/ct_list.R")
  expect_false(tidy)

  # chemi_alerts explicitly sets tidy=FALSE
  tidy <- extract_tidy_flag("../../R/chemi_alerts.R")
  expect_false(tidy)
})

test_that("extract_tidy_flag defaults to TRUE when not found", {
  # For functions without generic_request calls or with no tidy param,
  # should default to TRUE
  # Create a temporary test file
  temp_file <- tempfile(fileext = ".R")
  writeLines(c(
    "test_func <- function(x) {",
    "  # No generic_request call",
    "  return(x)",
    "}"
  ), temp_file)

  tidy <- extract_tidy_flag(temp_file)
  expect_true(tidy)

  unlink(temp_file)
})

# TGEN-03: No-parameter functions ----

test_that("generate_test_file handles static endpoints (no params)", {
  # Use withr for temp directory
  withr::with_tempdir({
    # Create temp output directory
    test_dir <- file.path(getwd(), "tests")
    dir.create(test_dir, recursive = TRUE)

    # Generate test for ct_lists_all (has parameters but testing the pattern)
    # Better: create a mock static endpoint function
    mock_file <- file.path(getwd(), "mock_static.R")
    writeLines(c(
      "mock_static <- function() {",
      "  generic_request(",
      "    query = NULL,",
      "    endpoint = 'test',",
      "    method = 'GET',",
      "    batch_limit = 0",
      "  )",
      "}"
    ), mock_file)

    test_file <- generate_test_file("mock_static", mock_file, test_dir)

    # Read generated test
    test_content <- readLines(test_file)
    test_text <- paste(test_content, collapse = "\n")

    # Should call function with no arguments
    expect_true(grepl("mock_static\\(\\)", test_text))

    # Should NOT have a batch test (static endpoints don't batch)
    # Count number of vcr::use_cassette calls - should be 1 (single test only)
    cassette_count <- length(grep("vcr::use_cassette", test_content))
    expect_equal(cassette_count, 1)

    # Should have unique cassette name
    expect_true(grepl("mock_static_single", test_text))
  })
})

# TGEN-04: path_params handling ----

test_that("get_test_value_for_param handles path-related parameters", {
  # Test path parameter mapping
  expect_equal(get_test_value_for_param("start"), 0L)
  expect_equal(get_test_value_for_param("end"), 100L)
  expect_equal(get_test_value_for_param("property_name"), "MolWeight")

  # Test medium (for environmental data)
  expect_equal(get_test_value_for_param("medium"), "water")

  # Test study parameters
  expect_equal(get_test_value_for_param("study_id"), "12345")
  expect_equal(get_test_value_for_param("study_type"), "acute")
})

test_that("generated test includes appropriate values for path_params", {
  withr::with_tempdir({
    test_dir <- file.path(getwd(), "tests")
    dir.create(test_dir, recursive = TRUE)

    # Create mock function with path_params pattern
    mock_file <- file.path(getwd(), "mock_path.R")
    writeLines(c(
      "mock_path <- function(property_name, start, end) {",
      "  generic_request(",
      "    query = property_name,",
      "    endpoint = 'test',",
      "    method = 'GET',",
      "    batch_limit = 1,",
      "    path_params = c(start = start, end = end)",
      "  )",
      "}"
    ), mock_file)

    test_file <- generate_test_file("mock_path", mock_file, test_dir)
    test_content <- readLines(test_file)
    test_text <- paste(test_content, collapse = "\n")

    # Should include property_name parameter in call
    expect_true(grepl('property_name = "MolWeight"', test_text, fixed = TRUE))
  })
})

# TGEN-05: Unique cassette names ----

test_that("generate_test_file produces unique cassette names per variant", {
  withr::with_tempdir({
    test_dir <- file.path(getwd(), "tests")
    dir.create(test_dir, recursive = TRUE)

    # Use absolute path to R file from saved project root
    r_file <- file.path(PROJECT_ROOT, "R", "ct_hazard.R")

    # Generate test for ct_hazard (has parameters)
    test_file <- generate_test_file("ct_hazard", r_file, test_dir)

    # Read generated test
    test_content <- readLines(test_file)
    test_text <- paste(test_content, collapse = "\n")

    # Should have three unique cassette names
    expect_true(grepl('ct_hazard_single', test_text, fixed = TRUE))
    expect_true(grepl('ct_hazard_batch', test_text, fixed = TRUE))

    # Extract all cassette names
    cassette_lines <- grep("use_cassette", test_content, value = TRUE)

    # Should have exactly 2 cassette calls (single + batch)
    expect_equal(length(cassette_lines), 2)

    # Cassette names should be unique
    cassette_names <- stringr::str_extract(cassette_lines, '"[^"]+"')
    expect_equal(length(unique(cassette_names)), length(cassette_names))
  })
})

test_that("all cassette names follow {function_name}_{variant} pattern", {
  withr::with_tempdir({
    test_dir <- file.path(getwd(), "tests")
    dir.create(test_dir, recursive = TRUE)

    # Test with ct_list (has tidy=FALSE)
    r_file <- file.path(PROJECT_ROOT, "R", "ct_list.R")
    test_file <- generate_test_file("ct_list", r_file, test_dir)
    test_content <- readLines(test_file)
    test_text <- paste(test_content, collapse = "\n")

    # Extract cassette names
    cassette_names <- stringr::str_extract_all(test_text, '"ct_list_[a-z]+"')[[1]]

    # All should start with function name
    expect_true(all(grepl("^\"ct_list_", cassette_names)))

    # Should have expected variants
    expect_true(any(grepl("ct_list_single", cassette_names)))
    expect_true(any(grepl("ct_list_batch", cassette_names)))
  })
})

# Integration test: Verify assertion types match tidy flag ----

test_that("generated tests assert tibble for tidy=TRUE functions", {
  withr::with_tempdir({
    test_dir <- file.path(getwd(), "tests")
    dir.create(test_dir, recursive = TRUE)

    # ct_hazard has tidy=TRUE (default)
    r_file <- file.path(PROJECT_ROOT, "R", "ct_hazard.R")
    test_file <- generate_test_file("ct_hazard", r_file, test_dir)
    test_content <- readLines(test_file)
    test_text <- paste(test_content, collapse = "\n")

    # Should use expect_s3_class for tibble
    expect_true(grepl('expect_s3_class\\(result, "tbl_df"\\)', test_text))

    # Should NOT use expect_type for list
    expect_false(grepl('expect_type\\(result, "list"\\)', test_text))
  })
})

test_that("generated tests assert list for tidy=FALSE functions", {
  withr::with_tempdir({
    test_dir <- file.path(getwd(), "tests")
    dir.create(test_dir, recursive = TRUE)

    # ct_list has tidy=FALSE
    r_file <- file.path(PROJECT_ROOT, "R", "ct_list.R")
    test_file <- generate_test_file("ct_list", r_file, test_dir)
    test_content <- readLines(test_file)
    test_text <- paste(test_content, collapse = "\n")

    # Should use expect_type for list
    expect_true(grepl('expect_type\\(result, "list"\\)', test_text))

    # Should NOT use expect_s3_class for tibble
    expect_false(grepl('expect_s3_class\\(result, "tbl_df"\\)', test_text))
  })
})

# Edge cases ----

test_that("extract_function_formals handles functions with complex signatures", {
  # Test with chemi_alerts which has multiple parameters
  formals <- extract_function_formals("../../R/chemi_alerts.R", "chemi_alerts")

  expect_type(formals, "list")
  expect_true("query" %in% names(formals))
  expect_true("idType" %in% names(formals))
  expect_true("options" %in% names(formals))
})

test_that("generate_test_file handles functions with defaults", {
  withr::with_tempdir({
    test_dir <- file.path(getwd(), "tests")
    dir.create(test_dir, recursive = TRUE)

    # ct_list has extract_dtxsids = TRUE default
    r_file <- file.path(PROJECT_ROOT, "R", "ct_list.R")
    test_file <- generate_test_file("ct_list", r_file, test_dir)

    # Should generate successfully
    expect_true(file.exists(test_file))

    # Read content
    test_content <- readLines(test_file)
    test_text <- paste(test_content, collapse = "\n")

    # Should use primary parameter (list_name)
    expect_true(grepl('list_name', test_text))
  })
})
