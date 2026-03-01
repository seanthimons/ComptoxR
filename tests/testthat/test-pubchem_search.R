# Tests for pubchem_search and pubchem_search_bulk
# These tests interact with the public PubChem API

test_that("pubchem_search works with compound name", {
  skip_on_cran()
  skip_if_offline()
  
  result <- pubchem_search(query = "aspirin", input_type = "name")
  
  expect_s3_class(result, "tbl_df")
  expect_true(ncol(result) > 0)
})

test_that("pubchem_search works with CID and properties", {
  skip_on_cran()
  skip_if_offline()
  
  result <- pubchem_search(
    query = "2244", 
    input_type = "cid",
    properties = c("MolecularFormula", "MolecularWeight")
  )
  
  expect_s3_class(result, "tbl_df")
  expect_true("MolecularFormula" %in% names(result) || "molecularformula" %in% tolower(names(result)))
})

test_that("pubchem_search works with SMILES", {
  skip_on_cran()
  skip_if_offline()
  
  # Simple SMILES for water
  result <- pubchem_search(
    query = "O", 
    input_type = "smiles"
  )
  
  expect_s3_class(result, "tbl_df")
  expect_true(ncol(result) > 0)
})

test_that("pubchem_search validates input_type", {
  expect_error(
    pubchem_search(query = "aspirin", input_type = "invalid"),
    "input_type must be one of"
  )
})

test_that("pubchem_search validates output type", {
  expect_error(
    pubchem_search(query = "aspirin", output = "invalid"),
    "output must be one of"
  )
})

test_that("pubchem_search requires query parameter", {
  expect_error(
    pubchem_search(query = NULL),
    "query must be a non-empty value"
  )
  
  expect_error(
    pubchem_search(query = ""),
    "query must be a non-empty value"
  )
})

test_that("pubchem_search_bulk works with multiple compounds", {
  skip_on_cran()
  skip_if_offline()
  
  result <- pubchem_search_bulk(
    queries = c("aspirin", "caffeine"),
    input_type = "name"
  )
  
  expect_s3_class(result, "tbl_df")
  expect_true("query_input" %in% names(result))
  expect_true(nrow(result) > 0)
})

test_that("pubchem_search_bulk works with CIDs", {
  skip_on_cran()
  skip_if_offline()
  
  result <- pubchem_search_bulk(
    queries = c("2244", "2519"),
    input_type = "cid",
    properties = c("MolecularFormula", "MolecularWeight")
  )
  
  expect_s3_class(result, "tbl_df")
  expect_true("query_input" %in% names(result))
})

test_that("pubchem_search_bulk validates queries parameter", {
  expect_error(
    pubchem_search_bulk(queries = NULL),
    "queries must be a non-empty character vector"
  )
  
  expect_error(
    pubchem_search_bulk(queries = c()),
    "queries must be a non-empty character vector"
  )
})

test_that("pubchem_search_bulk removes duplicates", {
  skip_on_cran()
  skip_if_offline()
  
  # Should only query once for the duplicate
  result <- pubchem_search_bulk(
    queries = c("aspirin", "aspirin", "caffeine"),
    input_type = "name"
  )
  
  expect_s3_class(result, "tbl_df")
  # We expect only 2 unique compounds
  unique_queries <- unique(result$query_input)
  expect_lte(length(unique_queries), 2)
})

test_that("pubchem_search_bulk handles empty values", {
  result <- suppressWarnings(
    pubchem_search_bulk(queries = c(NA, "", "   "))
  )
  
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) == 0)
})
