# Tests for chemi_stdizer_records
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_stdizer_records works without parameters", {
    vcr::use_cassette("chemi_stdizer_records_basic", {
        result <- chemi_stdizer_records()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_stdizer_records works with documented example", {
    vcr::use_cassette("chemi_stdizer_records_example", {
        result <- chemi_stdizer_records()
        expect_true(!is.null(result))
    })
})
