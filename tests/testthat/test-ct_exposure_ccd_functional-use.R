# Tests for ct_exposure_ccd_functional-use
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_ccd_functional-use works without parameters", {
    vcr::use_cassette("ct_exposure_ccd_functional-use_basic", {
        result <- `ct_exposure_ccd_functional-use`()
        {
            expect_true(!is.null(result))
        }
    })
})
