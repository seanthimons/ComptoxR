# Tests for ct_exposure_functional-use_probability
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_functional-use_probability works without parameters", {
    vcr::use_cassette("ct_exposure_functional-use_probability_basic", {
        result <- `ct_exposure_functional-use_probability`()
        {
            expect_true(!is.null(result))
        }
    })
})
