# Tests for ct_related
# Generated using helper-test-generator.R


test_that("ct_related works with valid input", {
    vcr::use_cassette("ct_related_dtxsid", {
        result <- ct_related(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_related handles batch requests", {
    vcr::use_cassette("ct_related_batch", {
        result <- ct_related(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_related handles invalid input gracefully", {
    vcr::use_cassette("ct_related_error", {
        expect_warning(result <- ct_related(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
