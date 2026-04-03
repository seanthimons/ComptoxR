test_that("pubchem_synonyms returns tidy tibble for single CID", {
  vcr::use_cassette("pubchem_synonyms_single_2244", {
    result <- pubchem_synonyms(2244)
  })
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("cid", "synonym"))
  expect_true(nrow(result) > 0)
  expect_true(any(grepl("aspirin", result$synonym, ignore.case = TRUE)))
})

test_that("pubchem_synonyms returns bulk results", {
  vcr::use_cassette("pubchem_synonyms_bulk_2244_6623", {
    result <- pubchem_synonyms(c(2244, 6623))
  })
  expect_s3_class(result, "tbl_df")
  expect_true(all(c(2244, 6623) %in% result$cid))
})

test_that("pubchem_synonyms tidy=FALSE returns list", {
  vcr::use_cassette("pubchem_synonyms_list_2244", {
    result <- pubchem_synonyms(2244, tidy = FALSE)
  })
  expect_type(result, "list")
  expect_true(length(result) > 0)
})

test_that("pubchem_synonyms rejects empty CID", {
  expect_error(pubchem_synonyms(integer(0)))
})
