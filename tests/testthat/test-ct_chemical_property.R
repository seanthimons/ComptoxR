# Tests for ct_chemical_property
# Generated using helper-test-generator.R


test_that("ct_chemical_property works with valid input", {
    vcr::use_cassette("ct_chemical_property_query", {
        result <- ct_chemical_property(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_chemical_property handles batch requests", {
    vcr::use_cassette("ct_chemical_property_batch", {
        result <- ct_chemical_property(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_chemical_property handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_property_error", {
            expect_warning(result <- ct_chemical_property(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
