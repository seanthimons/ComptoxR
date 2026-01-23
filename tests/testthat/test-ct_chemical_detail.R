# Tests for ct_chemical_detail
# Generated using helper-test-generator.R


test_that("ct_chemical_detail works with valid input", {
    vcr::use_cassette("ct_chemical_detail_query", {
        result <- ct_chemical_detail(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_chemical_detail handles batch requests", {
    vcr::use_cassette("ct_chemical_detail_batch", {
        result <- ct_chemical_detail(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_chemical_detail handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_detail_error", {
            expect_warning(result <- ct_chemical_detail(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
