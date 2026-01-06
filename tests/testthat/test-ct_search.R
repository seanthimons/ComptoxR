# Tests for ct_search
# Generated using helper-test-generator.R


test_that("ct_search works with valid input", {
    vcr::use_cassette("ct_search_smiles", {
        result <- ct_search(smiles = "C=O")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_search handles batch requests", {
    vcr::use_cassette("ct_search_batch", {
        result <- ct_search(smiles = c("C=O", "c1ccccc1", "CCO"
        ))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_search handles invalid input gracefully", {
    vcr::use_cassette("ct_search_error", {
        expect_warning(result <- ct_search(smiles = "INVALID_SMILES"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
