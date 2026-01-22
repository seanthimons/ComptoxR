# Tests for chemi_classyfire
# Generated using helper-test-generator.R


test_that("chemi_classyfire works with valid input", {
    vcr::use_cassette("chemi_classyfire_smiles", {
        result <- chemi_classyfire(smiles = "C=O")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("chemi_classyfire handles batch requests", {
    vcr::use_cassette("chemi_classyfire_batch", {
        result <- chemi_classyfire(smiles = c("C=O", "c1ccccc1", 
        "CCO"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("chemi_classyfire handles invalid input gracefully", 
    {
        vcr::use_cassette("chemi_classyfire_error", {
            expect_warning(result <- chemi_classyfire(smiles = "INVALID_SMILES"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
