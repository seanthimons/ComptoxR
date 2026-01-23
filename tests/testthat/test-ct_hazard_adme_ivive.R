# Tests for ct_hazard_adme_ivive
# Generated using helper-test-generator.R


test_that("ct_hazard_adme_ivive works with valid input", {
    vcr::use_cassette("ct_hazard_adme_ivive_query", {
        result <- ct_hazard_adme_ivive(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_hazard_adme_ivive handles batch requests", {
    vcr::use_cassette("ct_hazard_adme_ivive_batch", {
        result <- ct_hazard_adme_ivive(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_hazard_adme_ivive handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_hazard_adme_ivive_error", {
            expect_warning(result <- ct_hazard_adme_ivive(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
