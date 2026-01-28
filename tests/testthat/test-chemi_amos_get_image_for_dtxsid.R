# Tests for chemi_amos_get_image_for_dtxsid
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_get_image_for_dtxsid works without parameters", {
    vcr::use_cassette("chemi_amos_get_image_for_dtxsid_basic", {
        result <- chemi_amos_get_image_for_dtxsid()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_get_image_for_dtxsid works with documented example", {
    vcr::use_cassette("chemi_amos_get_image_for_dtxsid_example", {
        result <- chemi_amos_get_image_for_dtxsid()
        expect_true(!is.null(result))
    })
})
