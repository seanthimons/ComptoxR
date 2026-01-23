# Tests for ct_exposure_seem_demographic
# Generated using helper-test-generator.R


test_that("ct_exposure_seem_demographic works with valid input", 
    {
        vcr::use_cassette("ct_exposure_seem_demographic_query", 
            {
                result <- ct_exposure_seem_demographic(query = "DTXSID7020182")
                {
                  expect_s3_class(result, "tbl_df")
                  expect_true(ncol(result) > 0)
                }
            })
    })

test_that("ct_exposure_seem_demographic handles batch requests", 
    {
        vcr::use_cassette("ct_exposure_seem_demographic_batch", 
            {
                result <- ct_exposure_seem_demographic(query = c("DTXSID7020182", 
                "DTXSID5032381"))
                expect_s3_class(result, "tbl_df")
                expect_true(nrow(result) > 0)
            })
    })

test_that("ct_exposure_seem_demographic handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_exposure_seem_demographic_error", 
            {
                expect_warning(result <- ct_exposure_seem_demographic(query = "INVALID_ID"))
                expect_true(is.null(result) || nrow(result) == 
                  0)
            })
    })
