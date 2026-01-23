# Tests for ct_exposure_mmdb_single_sample_by_medium
# Generated using helper-test-generator.R


test_that("ct_exposure_mmdb_single_sample_by_medium works with valid input", 
    {
        vcr::use_cassette("ct_exposure_mmdb_single_sample_by_medium_query", 
            {
                result <- ct_exposure_mmdb_single_sample_by_medium(query = "DTXSID7020182")
                {
                  expect_s3_class(result, "tbl_df")
                  expect_true(ncol(result) > 0)
                }
            })
    })

test_that("ct_exposure_mmdb_single_sample_by_medium handles batch requests", 
    {
        vcr::use_cassette("ct_exposure_mmdb_single_sample_by_medium_batch", 
            {
                result <- ct_exposure_mmdb_single_sample_by_medium(query = c("DTXSID7020182", 
                "DTXSID5032381"))
                expect_s3_class(result, "tbl_df")
                expect_true(nrow(result) > 0)
            })
    })

test_that("ct_exposure_mmdb_single_sample_by_medium handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_exposure_mmdb_single_sample_by_medium_error", 
            {
                expect_warning(result <- ct_exposure_mmdb_single_sample_by_medium(query = "INVALID_ID"))
                expect_true(is.null(result) || nrow(result) == 
                  0)
            })
    })
