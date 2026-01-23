# Tests for chemi_classyfire
# Generated using helper-test-generator.R


test_that("chemi_classyfire works with valid input", {
    vcr::use_cassette("chemi_classyfire_dtxsid", {
        result <- chemi_classyfire(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("chemi_classyfire handles batch requests", {
    vcr::use_cassette("chemi_classyfire_batch", {
        result <- chemi_classyfire(query = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("chemi_classyfire handles invalid input gracefully", 
    {
        vcr::use_cassette("chemi_classyfire_error", {
            expect_warning(result <- chemi_classyfire(query = "INVALID_DTXSID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
