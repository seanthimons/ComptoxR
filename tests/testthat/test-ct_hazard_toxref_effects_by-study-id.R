# Tests for ct_hazard_toxref_effects_by-study-id
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_hazard_toxref_effects_by-study-id works without parameters", {
    vcr::use_cassette("ct_hazard_toxref_effects_by-study-id_basic", {
        result <- `ct_hazard_toxref_effects_by-study-id`()
        {
            expect_true(!is.null(result))
        }
    })
})
