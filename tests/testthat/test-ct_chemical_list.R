# Tests for ct_chemical_list
# Generated using helper-test-generator.R


test_that("ct_chemical_list works with valid input", {
    vcr::use_cassette("ct_chemical_list_query", {
        result <- ct_chemical_list(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_chemical_list handles batch requests", {
    vcr::use_cassette("ct_chemical_list_batch", {
        result <- ct_chemical_list(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_chemical_list handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_list_error", {
            expect_warning(result <- ct_chemical_list(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
