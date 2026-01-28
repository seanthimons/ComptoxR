# Tests for chemi_search_maps
# Generated using metadata-based test generator
# Return type: unknown
# 


test_that("chemi_search_maps works without parameters", {
    vcr::use_cassette("chemi_search_maps_basic", {
        result <- chemi_search_maps()
        {
            expect_true(!is.null(result))
        }
    })
})
