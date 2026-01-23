# Tests for chemi_safety_section
# Generated using helper-test-generator.R


test_that("chemi_safety_section works with valid input", {
    vcr::use_cassette("chemi_safety_section_dtxsid", {
        result <- chemi_safety_section(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("chemi_safety_section handles batch requests", {
    vcr::use_cassette("chemi_safety_section_batch", {
        result <- chemi_safety_section(query = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("chemi_safety_section handles invalid input gracefully", 
    {
        vcr::use_cassette("chemi_safety_section_error", {
            expect_warning(result <- chemi_safety_section(query = "INVALID_DTXSID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
