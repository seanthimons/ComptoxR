# Tests for chemi_services_convert
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_services_convert works without parameters", {
    vcr::use_cassette("chemi_services_convert_basic", {
        result <- chemi_services_convert()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_services_convert works with documented example", {
    vcr::use_cassette("chemi_services_convert_example", {
        result <- chemi_services_convert()
        expect_true(!is.null(result))
    })
})
