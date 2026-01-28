# Tests for chemi_alerts_groups
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_alerts_groups works with single input", {
    vcr::use_cassette("chemi_alerts_groups_single", {
        result <- chemi_alerts_groups(id = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_alerts_groups works with documented example", {
    vcr::use_cassette("chemi_alerts_groups_example", {
        result <- chemi_alerts_groups(id = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_alerts_groups handles batch requests", {
    vcr::use_cassette("chemi_alerts_groups_batch", {
        result <- chemi_alerts_groups(id = c("DTXSID7020182", "DTXSID5032381", "DTXSID8024291"
        ))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_alerts_groups handles invalid input gracefully", {
    vcr::use_cassette("chemi_alerts_groups_error", {
        result <- suppressWarnings(chemi_alerts_groups(id = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
