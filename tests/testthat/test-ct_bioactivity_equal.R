# Tests for ct_bioactivity_equal
# Generated using helper-test-generator.R


test_that("ct_bioactivity_equal works with valid input", {
    vcr::use_cassette("ct_bioactivity_equal_query", {
        result <- ct_bioactivity_equal(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_bioactivity_equal handles batch requests", {
    vcr::use_cassette("ct_bioactivity_equal_batch", {
        result <- ct_bioactivity_equal(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_bioactivity_equal handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_bioactivity_equal_error", {
            expect_warning(result <- ct_bioactivity_equal(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
