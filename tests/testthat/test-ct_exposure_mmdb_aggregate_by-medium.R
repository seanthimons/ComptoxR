# Tests for ct_exposure_mmdb_aggregate_by-medium
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_mmdb_aggregate_by-medium works without parameters", {
    vcr::use_cassette("ct_exposure_mmdb_aggregate_by-medium_basic", {
        result <- `ct_exposure_mmdb_aggregate_by-medium`()
        {
            expect_true(!is.null(result))
        }
    })
})
