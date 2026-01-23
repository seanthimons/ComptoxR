# Tests for ct_chemical_list_by_name
# Generated using helper-test-generator.R


test_that("ct_chemical_list_by_name works with valid input", 
    {
        vcr::use_cassette("ct_chemical_list_by_name_query", {
            result <- ct_chemical_list_by_name(query = "DTXSID7020182")
            {
                expect_s3_class(result, "tbl_df")
                expect_true(ncol(result) > 0)
            }
        })
    })

test_that("ct_chemical_list_by_name handles batch requests", 
    {
        vcr::use_cassette("ct_chemical_list_by_name_batch", {
            result <- ct_chemical_list_by_name(query = c("DTXSID7020182", 
            "DTXSID5032381"))
            expect_s3_class(result, "tbl_df")
            expect_true(nrow(result) > 0)
        })
    })

test_that("ct_chemical_list_by_name handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_list_by_name_error", {
            expect_warning(result <- ct_chemical_list_by_name(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
