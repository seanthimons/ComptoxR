# Tests for chemi_alerts_operations
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_alerts_operations works without parameters", {
    vcr::use_cassette("chemi_alerts_operations_basic", {
        result <- chemi_alerts_operations()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_alerts_operations works with documented example", {
    vcr::use_cassette("chemi_alerts_operations_example", {
        result <- chemi_alerts_operations()
        expect_true(!is.null(result))
    })
})
