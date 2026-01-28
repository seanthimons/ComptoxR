# Tests for ct_chemical_start-with
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_start-with works without parameters", {
    vcr::use_cassette("ct_chemical_start-with_basic", {
        result <- `ct_chemical_start-with`()
        {
            expect_true(!is.null(result))
        }
    })
})
