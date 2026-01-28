# Tests for chemi_amos_record_type_count
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_record_type_count works without parameters", {
    vcr::use_cassette("chemi_amos_record_type_count_basic", {
        result <- chemi_amos_record_type_count()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_record_type_count works with documented example", {
    vcr::use_cassette("chemi_amos_record_type_count_example", {
        result <- chemi_amos_record_type_count()
        expect_true(!is.null(result))
    })
})
