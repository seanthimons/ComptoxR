# Tests for ct_exposure_functional-use_category
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_functional-use_category works without parameters", {
    vcr::use_cassette("ct_exposure_functional-use_category_basic", {
        result <- `ct_exposure_functional-use_category`()
        {
            expect_true(!is.null(result))
        }
    })
})
