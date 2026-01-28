# Tests for ct_exposure_ccd_chem-weight-fractions
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_ccd_chem-weight-fractions works without parameters", {
    vcr::use_cassette("ct_exposure_ccd_chem-weight-fractions_basic", {
        result <- `ct_exposure_ccd_chem-weight-fractions`()
        {
            expect_true(!is.null(result))
        }
    })
})
