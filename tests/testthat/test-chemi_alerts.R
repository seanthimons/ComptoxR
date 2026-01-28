# Tests for chemi_alerts
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_alerts works with single input", {
    vcr::use_cassette("chemi_alerts_single", {
        result <- chemi_alerts(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_alerts works with documented example", {
    vcr::use_cassette("chemi_alerts_example", {
        result <- chemi_alerts(query = c("50-00-0", "DTXSID7020182"))
        expect_true(!is.null(result))
    })
})

test_that("chemi_alerts handles invalid input gracefully", {
    vcr::use_cassette("chemi_alerts_error", {
        result <- suppressWarnings(chemi_alerts(query = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
