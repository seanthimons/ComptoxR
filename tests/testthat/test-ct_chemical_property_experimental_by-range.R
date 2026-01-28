# Tests for ct_chemical_property_experimental_by-range
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_property_experimental_by-range works without parameters", 
    {
        vcr::use_cassette("ct_chemical_property_experimental_by-range_basic", {
            result <- `ct_chemical_property_experimental_by-range`()
            {
                expect_true(!is.null(result))
            }
        })
    })
