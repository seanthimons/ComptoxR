# Tests for ct_chemical_msready_by-mass
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("ct_chemical_msready_by-mass works without parameters", {
    vcr::use_cassette("ct_chemical_msready_by-mass_basic", {
        result <- `ct_chemical_msready_by-mass`()
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})
