# Tests for chemi_resolver_getsubstance
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_resolver_getsubstance works with single input", {
    vcr::use_cassette("chemi_resolver_getsubstance_single", {
        result <- chemi_resolver_getsubstance(name = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_resolver_getsubstance works with documented example", {
    vcr::use_cassette("chemi_resolver_getsubstance_example", {
        result <- chemi_resolver_getsubstance(name = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_resolver_getsubstance handles batch requests", {
    vcr::use_cassette("chemi_resolver_getsubstance_batch", {
        result <- chemi_resolver_getsubstance(name = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_resolver_getsubstance handles invalid input gracefully", {
    vcr::use_cassette("chemi_resolver_getsubstance_error", {
        result <- suppressWarnings(chemi_resolver_getsubstance(name = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
