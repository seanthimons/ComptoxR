# Tests for chemi_stdizer_groups_recursive
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_stdizer_groups_recursive works without parameters", {
    vcr::use_cassette("chemi_stdizer_groups_recursive_basic", {
        result <- chemi_stdizer_groups_recursive()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_stdizer_groups_recursive works with documented example", {
    vcr::use_cassette("chemi_stdizer_groups_recursive_example", {
        result <- chemi_stdizer_groups_recursive()
        expect_true(!is.null(result))
    })
})
