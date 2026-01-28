# Tests for chemi_amos_record_counts
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_record_counts works without parameters", {
    vcr::use_cassette("chemi_amos_record_counts_basic", {
        result <- chemi_amos_record_counts()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_record_counts works with documented example", {
    vcr::use_cassette("chemi_amos_record_counts_example", {
        result <- chemi_amos_record_counts()
        expect_true(!is.null(result))
    })
})
