# Tests for chemi_safety_hcodes
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("chemi_safety_hcodes works without parameters", {
    vcr::use_cassette("chemi_safety_hcodes_basic", {
        result <- chemi_safety_hcodes()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_safety_hcodes works with documented example", {
    vcr::use_cassette("chemi_safety_hcodes_example", {
        result <- chemi_safety_hcodes()
        expect_true(!is.null(result))
    })
})
