# Tests for ct_exposure_mmdb_single-sample
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_mmdb_single-sample works without parameters", {
    vcr::use_cassette("ct_exposure_mmdb_single-sample_basic", {
        result <- `ct_exposure_mmdb_single-sample`()
        {
            expect_true(!is.null(result))
        }
    })
})
