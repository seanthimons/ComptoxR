# Tests for ct_chemical_property_experimental_name
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_property_experimental_name works without parameters", {
    vcr::use_cassette("ct_chemical_property_experimental_name_basic", {
        result <- ct_chemical_property_experimental_name()
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_chemical_property_experimental_name works with documented example", 
    {
        vcr::use_cassette("ct_chemical_property_experimental_name_example", {
            result <- ct_chemical_property_experimental_name()
            expect_true(!is.null(result))
        })
    })
