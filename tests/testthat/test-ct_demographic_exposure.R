# Tests for ct_demographic_exposure
# Generated using helper-test-generator.R


test_that("ct_demographic_exposure works with valid input", {
    vcr::use_cassette("ct_demographic_exposure_query", {
        result <- ct_demographic_exposure(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_demographic_exposure handles batch requests", {
    vcr::use_cassette("ct_demographic_exposure_batch", {
        result <- ct_demographic_exposure(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_demographic_exposure handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_demographic_exposure_error", {
            expect_warning(result <- ct_demographic_exposure(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
