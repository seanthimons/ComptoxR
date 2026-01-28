# Tests for chemi_amos_get_pdf
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_get_pdf works without parameters", {
    vcr::use_cassette("chemi_amos_get_pdf_basic", {
        result <- chemi_amos_get_pdf()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_get_pdf works with documented example", {
    vcr::use_cassette("chemi_amos_get_pdf_example", {
        result <- chemi_amos_get_pdf()
        expect_true(!is.null(result))
    })
})
