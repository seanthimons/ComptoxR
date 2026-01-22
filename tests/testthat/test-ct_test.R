# Tests for ct_test
# Generated using helper-test-generator.R


test_that("ct_test works with valid input", {
    vcr::use_cassette("ct_test_dtxsid", {
        result <- ct_test(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_test handles batch requests", {
    vcr::use_cassette("ct_test_batch", {
        result <- ct_test(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_test handles invalid input gracefully", {
    vcr::use_cassette("ct_test_error", {
        expect_warning(result <- ct_test(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
