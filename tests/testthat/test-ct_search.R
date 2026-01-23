# Tests for ct_search
# Generated using helper-test-generator.R


test_that("ct_search works with valid input", {
    vcr::use_cassette("ct_search_query", {
        result <- ct_search(query = "formaldehyde")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_search handles batch requests", {
    vcr::use_cassette("ct_search_batch", {
        result <- ct_search(query = c("formaldehyde", "benzene", "ethanol"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_search handles invalid input gracefully", {
    vcr::use_cassette("ct_search_error", {
        expect_warning(result <- ct_search(query = "INVALID_COMPOUND_NAME_XYZ123"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
