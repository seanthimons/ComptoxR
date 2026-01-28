# Tests for ct_hazard_toxref_effects_by-study-type
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_hazard_toxref_effects_by-study-type works without parameters", {
    vcr::use_cassette("ct_hazard_toxref_effects_by-study-type_basic", {
        result <- `ct_hazard_toxref_effects_by-study-type`()
        {
            expect_true(!is.null(result))
        }
    })
})
