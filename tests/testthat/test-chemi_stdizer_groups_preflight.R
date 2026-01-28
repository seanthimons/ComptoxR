# Tests for chemi_stdizer_groups_preflight
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_stdizer_groups_preflight works without parameters", {
    vcr::use_cassette("chemi_stdizer_groups_preflight_basic", {
        result <- chemi_stdizer_groups_preflight()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_stdizer_groups_preflight works with documented example", {
    vcr::use_cassette("chemi_stdizer_groups_preflight_example", {
        result <- chemi_stdizer_groups_preflight()
        expect_true(!is.null(result))
    })
})
