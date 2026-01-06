# Tests for chemi_hazard
# Generated using helper-test-generator.R


test_that("chemi_hazard works with valid input", {
    vcr::use_cassette("chemi_hazard_dtxsid", {
        result <- chemi_hazard(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("chemi_hazard handles batch requests", {
    vcr::use_cassette("chemi_hazard_batch", {
        result <- chemi_hazard(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("chemi_hazard handles invalid input gracefully", {
    vcr::use_cassette("chemi_hazard_error", {
        expect_warning(result <- chemi_hazard(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
