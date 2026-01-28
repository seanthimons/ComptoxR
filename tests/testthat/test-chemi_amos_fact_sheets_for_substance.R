# Tests for chemi_amos_fact_sheets_for_substance
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_fact_sheets_for_substance works without parameters", {
    vcr::use_cassette("chemi_amos_fact_sheets_for_substance_basic", {
        result <- chemi_amos_fact_sheets_for_substance()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_fact_sheets_for_substance works with documented example", {
    vcr::use_cassette("chemi_amos_fact_sheets_for_substance_example", {
        result <- chemi_amos_fact_sheets_for_substance()
        expect_true(!is.null(result))
    })
})
