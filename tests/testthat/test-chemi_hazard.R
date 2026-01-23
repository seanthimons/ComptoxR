# Tests for chemi_hazard
# Generated using helper-test-generator.R


test_that("chemi_hazard works with valid input", {
    vcr::use_cassette("chemi_hazard_dtxsid", {
        result <- chemi_hazard(query = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(length(result) > 0)
        }
    })
})

test_that("chemi_hazard handles invalid input gracefully", {
    vcr::use_cassette("chemi_hazard_error", {
        expect_warning(result <- chemi_hazard(query = "INVALID_DTXSID"))
        expect_true(is.null(result) || length(result) == 0)
    })
})
