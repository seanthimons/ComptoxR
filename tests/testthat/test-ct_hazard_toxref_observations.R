# Tests for ct_hazard_toxref_observations
# Generated using helper-test-generator.R


test_that("ct_hazard_toxref_observations works with valid input", 
    {
        vcr::use_cassette("ct_hazard_toxref_observations_query", 
            {
                result <- ct_hazard_toxref_observations(query = "DTXSID7020182")
                {
                  expect_s3_class(result, "tbl_df")
                  expect_true(ncol(result) > 0)
                }
            })
    })

test_that("ct_hazard_toxref_observations handles batch requests", 
    {
        vcr::use_cassette("ct_hazard_toxref_observations_batch", 
            {
                result <- ct_hazard_toxref_observations(query = c("DTXSID7020182", 
                "DTXSID5032381"))
                expect_s3_class(result, "tbl_df")
                expect_true(nrow(result) > 0)
            })
    })

test_that("ct_hazard_toxref_observations handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_hazard_toxref_observations_error", 
            {
                expect_warning(result <- ct_hazard_toxref_observations(query = "INVALID_ID"))
                expect_true(is.null(result) || nrow(result) == 
                  0)
            })
    })
