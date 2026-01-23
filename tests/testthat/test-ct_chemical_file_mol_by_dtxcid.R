# Tests for ct_chemical_file_mol_by_dtxcid
# Generated using helper-test-generator.R


test_that("ct_chemical_file_mol_by_dtxcid works with valid input", 
    {
        vcr::use_cassette("ct_chemical_file_mol_by_dtxcid_query", 
            {
                result <- ct_chemical_file_mol_by_dtxcid(query = "DTXSID7020182")
                {
                  expect_s3_class(result, "tbl_df")
                  expect_true(ncol(result) > 0)
                }
            })
    })

test_that("ct_chemical_file_mol_by_dtxcid handles batch requests", 
    {
        vcr::use_cassette("ct_chemical_file_mol_by_dtxcid_batch", 
            {
                result <- ct_chemical_file_mol_by_dtxcid(query = c("DTXSID7020182", 
                "DTXSID5032381"))
                expect_s3_class(result, "tbl_df")
                expect_true(nrow(result) > 0)
            })
    })

test_that("ct_chemical_file_mol_by_dtxcid handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_file_mol_by_dtxcid_error", 
            {
                expect_warning(result <- ct_chemical_file_mol_by_dtxcid(query = "INVALID_ID"))
                expect_true(is.null(result) || nrow(result) == 
                  0)
            })
    })
