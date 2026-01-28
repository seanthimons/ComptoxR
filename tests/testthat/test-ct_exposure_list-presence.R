# Tests for ct_exposure_list-presence
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_list-presence works without parameters", {
    vcr::use_cassette("ct_exposure_list-presence_basic", {
        result <- `ct_exposure_list-presence`()
        {
            expect_true(!is.null(result))
        }
    })
})
