# Tests for ct_hazard_toxref
# Generated using helper-test-generator.R


test_that("ct_hazard_toxref works with valid input", {
    vcr::use_cassette("ct_hazard_toxref_query", {
        result <- ct_hazard_toxref(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_hazard_toxref handles batch requests", {
    vcr::use_cassette("ct_hazard_toxref_batch", {
        result <- ct_hazard_toxref(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_hazard_toxref handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_hazard_toxref_error", {
            expect_warning(result <- ct_hazard_toxref(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
