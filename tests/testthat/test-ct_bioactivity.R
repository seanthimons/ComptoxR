# Tests for ct_bioactivity
# Generated using helper-test-generator.R


test_that("ct_bioactivity works with valid input", {
    vcr::use_cassette("ct_bioactivity_dtxsid", {
        result <- ct_bioactivity(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_bioactivity handles batch requests", {
    vcr::use_cassette("ct_bioactivity_batch", {
        result <- ct_bioactivity(dtxsid = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_bioactivity handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_bioactivity_error", {
            expect_warning(result <- ct_bioactivity(dtxsid = "INVALID_DTXSID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
