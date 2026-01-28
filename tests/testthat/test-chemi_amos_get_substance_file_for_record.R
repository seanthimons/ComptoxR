# Tests for chemi_amos_get_substance_file_for_record
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_get_substance_file_for_record works without parameters", {
    vcr::use_cassette("chemi_amos_get_substance_file_for_record_basic", {
        result <- chemi_amos_get_substance_file_for_record()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_get_substance_file_for_record works with documented example", 
    {
        vcr::use_cassette("chemi_amos_get_substance_file_for_record_example", {
            result <- chemi_amos_get_substance_file_for_record()
            expect_true(!is.null(result))
        })
    })
