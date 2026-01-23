# Tests for ct_hazard_genetox
# Generated using helper-test-generator.R


test_that("ct_hazard_genetox works with valid input", {
    vcr::use_cassette("ct_hazard_genetox_query", {
        result <- ct_hazard_genetox(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_hazard_genetox handles batch requests", {
    vcr::use_cassette("ct_hazard_genetox_batch", {
        result <- ct_hazard_genetox(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_hazard_genetox handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_hazard_genetox_error", {
            expect_warning(result <- ct_hazard_genetox(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
