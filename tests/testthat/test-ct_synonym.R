# Tests for ct_synonym
# Generated using helper-test-generator.R


test_that("ct_synonym works with valid input", {
    vcr::use_cassette("ct_synonym_dtxsid", {
        result <- ct_synonym(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_synonym handles batch requests", {
    vcr::use_cassette("ct_synonym_batch", {
        result <- ct_synonym(query = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_synonym handles invalid input gracefully", {
    vcr::use_cassette("ct_synonym_error", {
        expect_warning(result <- ct_synonym(query = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
