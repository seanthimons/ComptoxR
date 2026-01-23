# Tests for ct_bioactivity_data_aed
# Generated using helper-test-generator.R


test_that("ct_bioactivity_data_aed works with valid input", {
    vcr::use_cassette("ct_bioactivity_data_aed_query", {
        result <- ct_bioactivity_data_aed(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_bioactivity_data_aed handles batch requests", {
    vcr::use_cassette("ct_bioactivity_data_aed_batch", {
        result <- ct_bioactivity_data_aed(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_bioactivity_data_aed handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_bioactivity_data_aed_error", {
            expect_warning(result <- ct_bioactivity_data_aed(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
