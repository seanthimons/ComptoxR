# Tests for ct_ghs
# Generated using helper-test-generator.R


test_that("ct_ghs works with valid input", {
    vcr::use_cassette("ct_ghs_dtxsid", {
        result <- ct_ghs(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_ghs handles batch requests", {
    vcr::use_cassette("ct_ghs_batch", {
        result <- ct_ghs(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_ghs handles invalid input gracefully", {
    vcr::use_cassette("ct_ghs_error", {
        expect_warning(result <- ct_ghs(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
