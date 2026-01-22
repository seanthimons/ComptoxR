# Tests for ct_cancer
# Generated using helper-test-generator.R


test_that("ct_cancer works with valid input", {
    vcr::use_cassette("ct_cancer_dtxsid", {
        result <- ct_cancer(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_cancer handles batch requests", {
    vcr::use_cassette("ct_cancer_batch", {
        result <- ct_cancer(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_cancer handles invalid input gracefully", {
    vcr::use_cassette("ct_cancer_error", {
        expect_warning(result <- ct_cancer(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
