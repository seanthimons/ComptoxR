# Tests for ct_classify
# Generated using helper-test-generator.R


test_that("ct_classify works with valid input", {
    vcr::use_cassette("ct_classify_dtxsid", {
        result <- ct_classify(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_classify handles batch requests", {
    vcr::use_cassette("ct_classify_batch", {
        result <- ct_classify(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_classify handles invalid input gracefully", {
    vcr::use_cassette("ct_classify_error", {
        expect_warning(result <- ct_classify(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
