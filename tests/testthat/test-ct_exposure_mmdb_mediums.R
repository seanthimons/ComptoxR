# Tests for ct_exposure_mmdb_mediums
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_mmdb_mediums works without parameters", {
    vcr::use_cassette("ct_exposure_mmdb_mediums_basic", {
        result <- ct_exposure_mmdb_mediums()
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_exposure_mmdb_mediums works with documented example", {
    vcr::use_cassette("ct_exposure_mmdb_mediums_example", {
        result <- ct_exposure_mmdb_mediums()
        expect_true(!is.null(result))
    })
})
