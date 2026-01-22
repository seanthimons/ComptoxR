# Tests for chemi_rq
# Generated using helper-test-generator.R


test_that("chemi_rq works with valid input", {
    vcr::use_cassette("chemi_rq_dtxsid", {
        result <- chemi_rq(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("chemi_rq handles batch requests", {
    vcr::use_cassette("chemi_rq_batch", {
        result <- chemi_rq(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("chemi_rq handles invalid input gracefully", {
    vcr::use_cassette("chemi_rq_error", {
        expect_warning(result <- chemi_rq(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
