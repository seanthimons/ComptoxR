# Tests for chemi_resolver_resolve
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_resolver_resolve works without parameters", {
    vcr::use_cassette("chemi_resolver_resolve_basic", {
        result <- chemi_resolver_resolve()
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_resolver_resolve works with documented example", {
    vcr::use_cassette("chemi_resolver_resolve_example", {
        result <- chemi_resolver_resolve()
        expect_true(!is.null(result))
    })
})
