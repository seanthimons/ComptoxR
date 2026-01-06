# Tests for ct_properties
# Generated using helper-test-generator.R


test_that("ct_properties works with valid input", {
    vcr::use_cassette("ct_properties_dtxsid", {
        result <- ct_properties(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_properties handles batch requests", {
    vcr::use_cassette("ct_properties_batch", {
        result <- ct_properties(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_properties handles invalid input gracefully", {
    vcr::use_cassette("ct_properties_error", {
        expect_warning(result <- ct_properties(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
