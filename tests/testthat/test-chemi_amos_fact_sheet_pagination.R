# Tests for chemi_amos_fact_sheet_pagination
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_fact_sheet_pagination works without parameters", {
    vcr::use_cassette("chemi_amos_fact_sheet_pagination_basic", {
        result <- chemi_amos_fact_sheet_pagination()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_fact_sheet_pagination works with documented example", {
    vcr::use_cassette("chemi_amos_fact_sheet_pagination_example", {
        result <- chemi_amos_fact_sheet_pagination()
        expect_true(!is.null(result))
    })
})
