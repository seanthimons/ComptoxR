# Tests for chemi_safety
# Generated using helper-test-generator.R


test_that("chemi_safety works with valid input", {
    vcr::use_cassette("chemi_safety_dtxsid", {
        result <- chemi_safety(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("chemi_safety handles batch requests", {
    vcr::use_cassette("chemi_safety_batch", {
        result <- chemi_safety(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("chemi_safety handles invalid input gracefully", {
    vcr::use_cassette("chemi_safety_error", {
        expect_warning(result <- chemi_safety(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
