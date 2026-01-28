# Tests for ct_hazard_adme-ivive
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_hazard_adme-ivive works without parameters", {
    vcr::use_cassette("ct_hazard_adme-ivive_basic", {
        result <- `ct_hazard_adme-ivive`()
        {
            expect_true(!is.null(result))
        }
    })
})
