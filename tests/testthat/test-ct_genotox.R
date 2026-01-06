# Tests for ct_genotox
# Generated using helper-test-generator.R


test_that("ct_genotox works with valid input", {
    vcr::use_cassette("ct_genotox_dtxsid", {
        result <- ct_genotox(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_genotox handles batch requests", {
    vcr::use_cassette("ct_genotox_batch", {
        result <- ct_genotox(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_genotox handles invalid input gracefully", {
    vcr::use_cassette("ct_genotox_error", {
        expect_warning(result <- ct_genotox(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
