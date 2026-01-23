# Tests for ct_hazard_toxref_data_by_study_id
# Generated using helper-test-generator.R


test_that("ct_hazard_toxref_data_by_study_id works with valid input", 
    {
        vcr::use_cassette("ct_hazard_toxref_data_by_study_id_query", 
            {
                result <- ct_hazard_toxref_data_by_study_id(query = "DTXSID7020182")
                {
                  expect_s3_class(result, "tbl_df")
                  expect_true(ncol(result) > 0)
                }
            })
    })

test_that("ct_hazard_toxref_data_by_study_id handles batch requests", 
    {
        vcr::use_cassette("ct_hazard_toxref_data_by_study_id_batch", 
            {
                result <- ct_hazard_toxref_data_by_study_id(query = c("DTXSID7020182", 
                "DTXSID5032381"))
                expect_s3_class(result, "tbl_df")
                expect_true(nrow(result) > 0)
            })
    })

test_that("ct_hazard_toxref_data_by_study_id handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_hazard_toxref_data_by_study_id_error", 
            {
                expect_warning(result <- ct_hazard_toxref_data_by_study_id(query = "INVALID_ID"))
                expect_true(is.null(result) || nrow(result) == 
                  0)
            })
    })
