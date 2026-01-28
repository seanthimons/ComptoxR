# Tests for chemi_alerts_alerts
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_alerts_alerts works without parameters", {
    vcr::use_cassette("chemi_alerts_alerts_basic", {
        result <- chemi_alerts_alerts()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_alerts_alerts works with documented example", {
    vcr::use_cassette("chemi_alerts_alerts_example", {
        result <- chemi_alerts_alerts()
        expect_true(!is.null(result))
    })
})
