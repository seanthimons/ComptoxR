# Tests for ct_exposure_httk
# Generated using helper-test-generator.R


test_that("ct_exposure_httk works with valid input", {
    vcr::use_cassette("ct_exposure_httk_query", {
        result <- ct_exposure_httk(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_exposure_httk handles batch requests", {
    vcr::use_cassette("ct_exposure_httk_batch", {
        result <- ct_exposure_httk(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_exposure_httk handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_exposure_httk_error", {
            expect_warning(result <- ct_exposure_httk(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
