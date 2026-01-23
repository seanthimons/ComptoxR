# Tests for ct_bioactivity_assay
# Generated using helper-test-generator.R


test_that("ct_bioactivity_assay works with valid input", {
    vcr::use_cassette("ct_bioactivity_assay_query", {
        result <- ct_bioactivity_assay(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_bioactivity_assay handles batch requests", {
    vcr::use_cassette("ct_bioactivity_assay_batch", {
        result <- ct_bioactivity_assay(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_bioactivity_assay handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_bioactivity_assay_error", {
            expect_warning(result <- ct_bioactivity_assay(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
