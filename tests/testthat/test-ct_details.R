# Tests for ct_details
# Generated using helper-test-generator.R


test_that("ct_details works with valid input", {
    vcr::use_cassette("ct_details_dtxsid", {
        result <- ct_details(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_details handles batch requests", {
    vcr::use_cassette("ct_details_batch", {
        result <- ct_details(query = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_details handles invalid input gracefully", {
    vcr::use_cassette("ct_details_error", {
        expect_warning(result <- ct_details(query = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
