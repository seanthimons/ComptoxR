# Tests for ct_chemical_fate_predicted
# Generated using helper-test-generator.R


test_that("ct_chemical_fate_predicted works with valid input", 
    {
        vcr::use_cassette("ct_chemical_fate_predicted_query", 
            {
                result <- ct_chemical_fate_predicted(query = "DTXSID7020182")
                {
                  expect_s3_class(result, "tbl_df")
                  expect_true(ncol(result) > 0)
                }
            })
    })

test_that("ct_chemical_fate_predicted handles batch requests", 
    {
        vcr::use_cassette("ct_chemical_fate_predicted_batch", 
            {
                result <- ct_chemical_fate_predicted(query = c("DTXSID7020182", 
                "DTXSID5032381"))
                expect_s3_class(result, "tbl_df")
                expect_true(nrow(result) > 0)
            })
    })

test_that("ct_chemical_fate_predicted handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_fate_predicted_error", 
            {
                expect_warning(result <- ct_chemical_fate_predicted(query = "INVALID_ID"))
                expect_true(is.null(result) || nrow(result) == 
                  0)
            })
    })
