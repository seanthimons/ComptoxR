test_that("pubchem_properties returns default properties for single CID", {
  vcr::use_cassette("pubchem_properties_single_2244", {
    result <- pubchem_properties(2244)
  })
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) >= 1)
  expect_true("CID" %in% names(result))
  expect_true("MolecularFormula" %in% names(result))
  expect_true("MolecularWeight" %in% names(result))
})

test_that("pubchem_properties returns bulk results via POST", {
  vcr::use_cassette("pubchem_properties_bulk_2244_6623", {
    result <- pubchem_properties(c(2244, 6623))
  })
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_true(all(c(2244, 6623) %in% result$CID))
})

test_that("pubchem_properties accepts custom property set", {
  vcr::use_cassette("pubchem_properties_custom_2244", {
    result <- pubchem_properties(2244, properties = c("MolecularWeight", "XLogP"))
  })
  expect_s3_class(result, "tbl_df")
  expect_true("MolecularWeight" %in% names(result))
  expect_true("XLogP" %in% names(result))
})

test_that("pubchem_properties rejects invalid property names", {
  expect_error(
    pubchem_properties(2244, properties = c("MolecularWeight", "../evil")),
    "Invalid PubChem property"
  )
})

test_that("pubchem_properties rejects empty CID", {
  expect_error(pubchem_properties(integer(0)))
})

test_that("pubchem_properties returns empty tibble for invalid CID", {
  vcr::use_cassette("pubchem_properties_invalid_cid", {
    expect_warning(
      result <- pubchem_properties(999999999),
      "PubChem"
    )
  })
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})
