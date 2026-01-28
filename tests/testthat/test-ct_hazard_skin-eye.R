# Tests for ct_hazard_skin-eye
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_hazard_skin-eye works without parameters", {
    vcr::use_cassette("ct_hazard_skin-eye_basic", {
        result <- `ct_hazard_skin-eye`()
        {
            expect_true(!is.null(result))
        }
    })
})
