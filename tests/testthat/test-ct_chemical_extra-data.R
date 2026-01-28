# Tests for ct_chemical_extra-data
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_extra-data works without parameters", {
    vcr::use_cassette("ct_chemical_extra-data_basic", {
        result <- `ct_chemical_extra-data`()
        {
            expect_true(!is.null(result))
        }
    })
})
