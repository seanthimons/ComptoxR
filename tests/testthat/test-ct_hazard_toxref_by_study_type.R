# Tests for ct_hazard_toxref_by_study_type
# Generated using helper-test-generator.R


test_that("ct_hazard_toxref_by_study_type works with valid input", 
    {
        vcr::use_cassette("ct_hazard_toxref_by_study_type_query", 
            {
                result <- ct_hazard_toxref_by_study_type(query = "DTXSID7020182")
                {
                  expect_s3_class(result, "tbl_df")
                  expect_true(ncol(result) > 0)
                }
            })
    })

test_that("ct_hazard_toxref_by_study_type handles batch requests", 
    {
        vcr::use_cassette("ct_hazard_toxref_by_study_type_batch", 
            {
                result <- ct_hazard_toxref_by_study_type(query = c("DTXSID7020182", 
                "DTXSID5032381"))
                expect_s3_class(result, "tbl_df")
                expect_true(nrow(result) > 0)
            })
    })

test_that("ct_hazard_toxref_by_study_type handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_hazard_toxref_by_study_type_error", 
            {
                expect_warning(result <- ct_hazard_toxref_by_study_type(query = "INVALID_ID"))
                expect_true(is.null(result) || nrow(result) == 
                  0)
            })
    })
