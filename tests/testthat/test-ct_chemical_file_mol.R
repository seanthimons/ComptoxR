# Tests for ct_chemical_file_mol
# Generated using helper-test-generator.R


test_that("ct_chemical_file_mol works with valid input", {
    vcr::use_cassette("ct_chemical_file_mol_query", {
        result <- ct_chemical_file_mol(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_chemical_file_mol handles batch requests", {
    vcr::use_cassette("ct_chemical_file_mol_batch", {
        result <- ct_chemical_file_mol(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_chemical_file_mol handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_file_mol_error", {
            expect_warning(result <- ct_chemical_file_mol(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
