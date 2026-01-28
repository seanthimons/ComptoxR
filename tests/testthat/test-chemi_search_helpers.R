# Tests for chemi_search_helpers
# Generated using metadata-based test generator
# Return type: unknown
# MOL string suitable for API payload


test_that("chemi_search_helpers works without parameters", {
    vcr::use_cassette("chemi_search_helpers_basic", {
        result <- chemi_search_helpers()
        {
            expect_true(!is.null(result))
        }
    })
})
