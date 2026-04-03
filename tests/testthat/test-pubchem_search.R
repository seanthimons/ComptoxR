test_that("pubchem_search returns CIDs for name query", {
  vcr::use_cassette("pubchem_search_name_aspirin", {
    result <- pubchem_search("aspirin")
  })
  expect_s3_class(result, "tbl_df")
  expect_named(result, "cid")
  expect_true(2244 %in% result$cid)
})

test_that("pubchem_search works with SMILES via POST", {
  vcr::use_cassette("pubchem_search_smiles_aspirin", {
    # Aspirin SMILES
    result <- pubchem_search("CC(=O)OC1=CC=CC=C1C(=O)O", type = "smiles")
  })
  expect_s3_class(result, "tbl_df")
  expect_named(result, "cid")
  expect_true(2244 %in% result$cid)
})

test_that("pubchem_search works with InChIKey", {
  vcr::use_cassette("pubchem_search_inchikey_aspirin", {
    result <- pubchem_search("BSYNRYMUTXBXSQ-UHFFFAOYSA-N", type = "inchikey")
  })
  expect_s3_class(result, "tbl_df")
  expect_true(2244 %in% result$cid)
})

test_that("pubchem_search returns empty tibble for invalid name", {
  vcr::use_cassette("pubchem_search_name_invalid", {
    expect_warning(
      result <- pubchem_search("zzz_no_such_compound_xyz_12345"),
      "PubChem|No PubChem"
    )
  })
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("pubchem_search rejects invalid type argument", {
  expect_error(pubchem_search("aspirin", type = "invalid"))
})

test_that("pubchem_search rejects empty query", {
  expect_error(pubchem_search(""), "non-empty")
})
