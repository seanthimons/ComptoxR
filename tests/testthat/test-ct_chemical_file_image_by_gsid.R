# Tests for ct_chemical_file_image_by_gsid
# Generated using helper-test-generator.R


test_that("ct_chemical_file_image_by_gsid works with valid input", 
    {
        vcr::use_cassette("ct_chemical_file_image_by_gsid_query", 
            {
                result <- ct_chemical_file_image_by_gsid(query = "DTXSID7020182")
                {
                  expect_s3_class(result, "tbl_df")
                  expect_true(ncol(result) > 0)
                }
            })
    })

test_that("ct_chemical_file_image_by_gsid handles batch requests", 
    {
        vcr::use_cassette("ct_chemical_file_image_by_gsid_batch", 
            {
                result <- ct_chemical_file_image_by_gsid(query = c("DTXSID7020182", 
                "DTXSID5032381"))
                expect_s3_class(result, "tbl_df")
                expect_true(nrow(result) > 0)
            })
    })

test_that("ct_chemical_file_image_by_gsid handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_file_image_by_gsid_error", 
            {
                expect_warning(result <- ct_chemical_file_image_by_gsid(query = "INVALID_ID"))
                expect_true(is.null(result) || nrow(result) == 
                  0)
            })
    })
