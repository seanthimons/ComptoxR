# Tests for chemi_safety_rqcodes
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("chemi_safety_rqcodes works without parameters", {
    vcr::use_cassette("chemi_safety_rqcodes_basic", {
        result <- chemi_safety_rqcodes()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_safety_rqcodes works with documented example", {
    vcr::use_cassette("chemi_safety_rqcodes_example", {
        result <- chemi_safety_rqcodes()
        expect_true(!is.null(result))
    })
})
