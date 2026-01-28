# Tests for chemi_services_caspreflight
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_services_caspreflight works without parameters", {
    vcr::use_cassette("chemi_services_caspreflight_basic", {
        result <- chemi_services_caspreflight()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_services_caspreflight works with documented example", {
    vcr::use_cassette("chemi_services_caspreflight_example", {
        result <- chemi_services_caspreflight()
        expect_true(!is.null(result))
    })
})
