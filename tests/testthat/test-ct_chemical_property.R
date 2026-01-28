# Tests for ct_chemical_property
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_property works with single input", {
    vcr::use_cassette("ct_chemical_property_single", {
        result <- ct_chemical_property(dtxsid = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_chemical_property works with documented example", {
    vcr::use_cassette("ct_chemical_property_example", {
        result <- ct_chemical_property(dtxsid = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("ct_chemical_property handles batch requests", {
    vcr::use_cassette("ct_chemical_property_batch", {
        result <- ct_chemical_property(dtxsid = c("DTXSID7020182", "DTXSID5032381"
        ))
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_chemical_property handles invalid input gracefully", {
    vcr::use_cassette("ct_chemical_property_error", {
        result <- suppressWarnings(ct_chemical_property(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
