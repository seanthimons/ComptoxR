# Tests for ct_chemical_property_experimental_search_by_range
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_property_experimental_search_by_range works with single input", 
    {
        vcr::use_cassette("ct_chemical_property_experimental_search_by_range_single", 
            {
                result <- ct_chemical_property_experimental_search_by_range(propertyName = "DTXSID7020182")
                {
                  expect_true(!is.null(result))
                }
            })
    })

test_that("ct_chemical_property_experimental_search_by_range works with documented example", 
    {
        vcr::use_cassette("ct_chemical_property_experimental_search_by_range_example", 
            {
                result <- ct_chemical_property_experimental_search_by_range(propertyName = "DTXSID7020182")
                expect_true(!is.null(result))
            })
    })

test_that("ct_chemical_property_experimental_search_by_range handles batch requests", 
    {
        vcr::use_cassette("ct_chemical_property_experimental_search_by_range_batch", 
            {
                result <- ct_chemical_property_experimental_search_by_range(propertyName = c("DTXSID7020182", 
                "DTXSID5032381", "DTXSID8024291"))
                {
                  expect_true(!is.null(result))
                }
            })
    })

test_that("ct_chemical_property_experimental_search_by_range handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_property_experimental_search_by_range_error", 
            {
                result <- suppressWarnings(ct_chemical_property_experimental_search_by_range(propertyName = "INVALID_DTXSID_12345"))
                expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                  0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                  length(result) == 0))
            })
    })
