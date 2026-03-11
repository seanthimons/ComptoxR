# Tests for hook primitive functions

# Load hook functions (they're not exported, so we need to source them)
# Hook files are in R/hooks/ and contain @noRd functions
hook_files <- list.files(here::here("R/hooks"), pattern = "\\.R$", full.names = TRUE)
for (hook_file in hook_files) {
  source(hook_file)
}

test_that("hook functions can be loaded", {
  # This just ensures the hooks exist
  expect_true(exists("validate_similarity", mode = "function"))
  expect_true(exists("uppercase_query", mode = "function"))
  expect_true(exists("annotate_assay_if_requested", mode = "function"))
})

# ============================================================================
# Validation Hooks Tests
# ============================================================================

test_that("validate_similarity rejects non-numeric input", {
  mock_data <- list(params = list(similarity = "0.8"))

  expect_error(
    validate_similarity(mock_data),
    "must be numeric"
  )
})

test_that("validate_similarity rejects out-of-range values", {
  # Test below range
  mock_data_low <- list(params = list(similarity = -0.1))
  expect_error(
    validate_similarity(mock_data_low),
    "between 0 and 1"
  )

  # Test above range
  mock_data_high <- list(params = list(similarity = 1.5))
  expect_error(
    validate_similarity(mock_data_high),
    "between 0 and 1"
  )
})

test_that("validate_similarity accepts valid input and passes data through", {
  mock_data <- list(
    params = list(similarity = 0.8, other_param = "test")
  )

  result <- validate_similarity(mock_data)
  expect_identical(result, mock_data)
})

# ============================================================================
# List Hooks Tests
# ============================================================================

test_that("uppercase_query converts query to uppercase", {
  mock_data <- list(params = list(query = "prodwater"))

  result <- uppercase_query(mock_data)
  expect_equal(result$params$query, "PRODWATER")
})

test_that("extract_dtxsids_if_requested returns original when FALSE", {
  mock_result <- list(
    listName = "TEST_LIST",
    dtxsids = "DTXSID1,DTXSID2,DTXSID3"
  )
  mock_data <- list(
    result = mock_result,
    params = list(extract_dtxsids = FALSE)
  )

  result <- extract_dtxsids_if_requested(mock_data)
  expect_identical(result, mock_result)
})

test_that("extract_dtxsids_if_requested splits DTXSIDs when TRUE (single result)", {
  mock_result <- list(
    listName = "TEST_LIST",
    dtxsids = "DTXSID1,DTXSID2,DTXSID3"
  )
  mock_data <- list(
    result = mock_result,
    params = list(extract_dtxsids = TRUE)
  )

  result <- extract_dtxsids_if_requested(mock_data)
  expect_type(result, "character")
  expect_equal(length(result), 3)
  expect_true(all(c("DTXSID1", "DTXSID2", "DTXSID3") %in% result))
})

test_that("extract_dtxsids_if_requested handles duplicate names (multiple results)", {
  # Multiple results with duplicate 'dtxsids' names
  mock_result <- list(
    listName = "TEST_LIST1",
    dtxsids = "DTXSID1,DTXSID2",
    listName = "TEST_LIST2",
    dtxsids = "DTXSID3,DTXSID1"  # Duplicate DTXSID1 to test deduplication
  )
  mock_data <- list(
    result = mock_result,
    params = list(extract_dtxsids = TRUE)
  )

  result <- extract_dtxsids_if_requested(mock_data)
  expect_type(result, "character")
  expect_equal(length(unique(result)), length(result))  # All unique
  expect_true(all(c("DTXSID1", "DTXSID2", "DTXSID3") %in% result))
})

test_that("lists_all_transform returns tibble with correct projection", {
  # Mock ct_chemical_list_all to return test data
  local_mocked_bindings(
    ct_chemical_list_all = function(projection = NULL) {
      tibble::tibble(
        listName = c("List1", "List2"),
        listType = c("Type1", "Type2"),
        dtxsids = if (projection == "chemicallistwithdtxsids") {
          c("DTXSID1,DTXSID2", "DTXSID3,DTXSID4")
        } else {
          NULL
        }
      )
    }
  )

  # Test without return_dtxsid
  mock_data <- list(params = list(return_dtxsid = FALSE, coerce = FALSE))
  result <- lists_all_transform(mock_data)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
})

test_that("lists_all_transform coerces dtxsids when requested", {
  local_mocked_bindings(
    ct_chemical_list_all = function(projection = NULL) {
      tibble::tibble(
        listName = c("List1", "List2"),
        dtxsids = c("DTXSID1,DTXSID2", "DTXSID3,DTXSID4")
      )
    }
  )

  mock_data <- list(params = list(return_dtxsid = TRUE, coerce = TRUE))
  result <- lists_all_transform(mock_data)

  expect_type(result, "list")
  expect_equal(length(result), 2)
  expect_true(all(names(result) %in% c("List1", "List2")))
  expect_type(result$List1$dtxsids, "character")
  expect_equal(length(result$List1$dtxsids), 2)
})

test_that("format_compound_list_result formats output correctly", {
  mock_result <- list(
    list(c("List1", "List2", "List3"))
  )
  mock_data <- list(
    result = mock_result,
    params = list(query = "DTXSID1")
  )

  result <- format_compound_list_result(mock_data)
  expect_type(result, "list")
  expect_equal(names(result), "DTXSID1")
  expect_equal(length(result$DTXSID1), 3)
})

test_that("format_compound_list_result handles no results", {
  mock_result <- list(
    list()
  )
  mock_data <- list(
    result = mock_result,
    params = list(query = "DTXSID_INVALID")
  )

  result <- format_compound_list_result(mock_data)
  expect_type(result, "list")
  expect_equal(length(result), 0)  # compact() removes NULL
})

# ============================================================================
# Bioactivity Hooks Tests
# ============================================================================

test_that("annotate_assay_if_requested returns unchanged when FALSE", {
  mock_result <- tibble::tibble(
    aeid = c(1L, 2L),
    value = c(0.5, 0.8)
  )
  mock_data <- list(
    result = mock_result,
    params = list(annotate = FALSE)
  )

  result <- annotate_assay_if_requested(mock_data)
  expect_identical(result, mock_result)
})

test_that("annotate_assay_if_requested joins when annotate=TRUE", {
  local_mocked_bindings(
    ct_bioactivity_assay = function(...) {
      tibble::tibble(aeid = c(1L, 2L), assay_name = c("Assay1", "Assay2"))
    }
  )

  mock_result <- tibble::tibble(
    aeid = c(1L, 1L, 2L),
    value = c(0.5, 0.8, 0.3)
  )
  mock_data <- list(
    result = mock_result,
    params = list(annotate = TRUE)
  )

  result <- annotate_assay_if_requested(mock_data)
  expect_true("assay_name" %in% names(result))
  expect_equal(nrow(result), 3)
  expect_equal(result$assay_name, c("Assay1", "Assay1", "Assay2"))
})
