# Tests for ct_exposure_ccd_production-volume
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_ccd_production-volume works without parameters", {
    vcr::use_cassette("ct_exposure_ccd_production-volume_basic", {
        result <- `ct_exposure_ccd_production-volume`()
        {
            expect_true(!is.null(result))
        }
    })
})
