# Tests for ct_exposure_ccd_monitoring-data
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_ccd_monitoring-data works without parameters", {
    vcr::use_cassette("ct_exposure_ccd_monitoring-data_basic", {
        result <- `ct_exposure_ccd_monitoring-data`()
        {
            expect_true(!is.null(result))
        }
    })
})
