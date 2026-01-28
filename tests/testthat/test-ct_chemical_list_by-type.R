# Tests for ct_chemical_list_by-type
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_list_by-type works without parameters", {
    vcr::use_cassette("ct_chemical_list_by-type_basic", {
        result <- `ct_chemical_list_by-type`()
        {
            expect_true(!is.null(result))
        }
    })
})
