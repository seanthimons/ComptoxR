# Tests for ct_functional_use
# Generated using helper-test-generator.R


test_that("ct_functional_use works with valid input", {
    vcr::use_cassette("ct_functional_use_dtxsid", {
        result <- ct_functional_use(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_functional_use handles batch requests", {
    vcr::use_cassette("ct_functional_use_batch", {
        result <- ct_functional_use(dtxsid = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_functional_use handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_functional_use_error", {
            expect_warning(result <- ct_functional_use(dtxsid = "INVALID_DTXSID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
