# Tests for chemi_predict
# Generated using helper-test-generator.R


test_that("chemi_predict works with valid input", {
    vcr::use_cassette("chemi_predict_dtxsid", {
        result <- chemi_predict(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("chemi_predict handles batch requests", {
    vcr::use_cassette("chemi_predict_batch", {
        result <- chemi_predict(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("chemi_predict handles invalid input gracefully", {
    vcr::use_cassette("chemi_predict_error", {
        expect_warning(result <- chemi_predict(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
