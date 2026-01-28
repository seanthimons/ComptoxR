# Tests for chemi_alerts_groups
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_alerts_groups works without parameters", {
    vcr::use_cassette("chemi_alerts_groups_basic", {
        result <- chemi_alerts_groups()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_alerts_groups works with documented example", {
    vcr::use_cassette("chemi_alerts_groups_example", {
        result <- chemi_alerts_groups()
        expect_true(!is.null(result))
    })
})
