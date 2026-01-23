# Tests for ct_hazard_hawc
# Generated using helper-test-generator.R


test_that("ct_hazard_hawc works with valid input", {
    vcr::use_cassette("ct_hazard_hawc_query", {
        result <- ct_hazard_hawc(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_hazard_hawc handles batch requests", {
    vcr::use_cassette("ct_hazard_hawc_batch", {
        result <- ct_hazard_hawc(query = c("DTXSID7020182", "DTXSID5032381"
        ))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_hazard_hawc handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_hazard_hawc_error", {
            expect_warning(result <- ct_hazard_hawc(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
