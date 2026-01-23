# Tests for ct_env_fate
# Generated using helper-test-generator.R


test_that("ct_env_fate works with valid input", {
    vcr::use_cassette("ct_env_fate_dtxsid", {
        result <- ct_env_fate(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_env_fate handles batch requests", {
    vcr::use_cassette("ct_env_fate_batch", {
        result <- ct_env_fate(query = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_env_fate handles invalid input gracefully", {
    vcr::use_cassette("ct_env_fate_error", {
        expect_warning(result <- ct_env_fate(query = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
