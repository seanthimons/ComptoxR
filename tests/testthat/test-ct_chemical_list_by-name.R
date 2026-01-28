# Tests for ct_chemical_list_by-name
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_list_by-name works without parameters", {
    vcr::use_cassette("ct_chemical_list_by-name_basic", {
        result <- `ct_chemical_list_by-name`()
        {
            expect_true(!is.null(result))
        }
    })
})
