# Tests for chemi_amos_spectrum_count_for_methodology
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_spectrum_count_for_methodology works without parameters", {
    vcr::use_cassette("chemi_amos_spectrum_count_for_methodology_basic", {
        result <- chemi_amos_spectrum_count_for_methodology()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_spectrum_count_for_methodology works with documented example", 
    {
        vcr::use_cassette("chemi_amos_spectrum_count_for_methodology_example", {
            result <- chemi_amos_spectrum_count_for_methodology()
            expect_true(!is.null(result))
        })
    })
