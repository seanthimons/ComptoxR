# Tests for chemi_resolver_resolve
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_resolver_resolve works with single input", {
    vcr::use_cassette("chemi_resolver_resolve_single", {
        result <- chemi_resolver_resolve(`queries = NULL` = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_resolver_resolve works with documented example", {
    vcr::use_cassette("chemi_resolver_resolve_example", {
        result <- chemi_resolver_resolve(queries = c("DTXSID901027719", "DTXSID20582510", 
            "DTXSID80109469"))
        expect_true(!is.null(result))
    })
})

test_that("chemi_resolver_resolve handles invalid input gracefully", {
    vcr::use_cassette("chemi_resolver_resolve_error", {
        result <- suppressWarnings(chemi_resolver_resolve(`queries = NULL` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
