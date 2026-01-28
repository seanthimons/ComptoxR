# Tests for chemi_amos_fact_sheet_pagination
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_fact_sheet_pagination works with single input", {
    vcr::use_cassette("chemi_amos_fact_sheet_pagination_single", {
        result <- chemi_amos_fact_sheet_pagination(limit = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_fact_sheet_pagination works with documented example", {
    vcr::use_cassette("chemi_amos_fact_sheet_pagination_example", {
        result <- chemi_amos_fact_sheet_pagination(limit = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_amos_fact_sheet_pagination handles batch requests", {
    vcr::use_cassette("chemi_amos_fact_sheet_pagination_batch", {
        result <- chemi_amos_fact_sheet_pagination(limit = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_amos_fact_sheet_pagination handles invalid input gracefully", {
    vcr::use_cassette("chemi_amos_fact_sheet_pagination_error", {
        result <- suppressWarnings(chemi_amos_fact_sheet_pagination(limit = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
