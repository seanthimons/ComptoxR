# Tests for chemi_resolver_classyfire
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_resolver_classyfire works with single input", {
    vcr::use_cassette("chemi_resolver_classyfire_single", {
        result <- chemi_resolver_classyfire(`query = NULL` = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_resolver_classyfire works with documented example", {
    vcr::use_cassette("chemi_resolver_classyfire_example", {
        result <- chemi_resolver_classyfire(query = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_resolver_classyfire handles batch requests", {
    vcr::use_cassette("chemi_resolver_classyfire_batch", {
        result <- chemi_resolver_classyfire(`query = NULL` = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_resolver_classyfire handles invalid input gracefully", {
    vcr::use_cassette("chemi_resolver_classyfire_error", {
        result <- suppressWarnings(chemi_resolver_classyfire(`query = NULL` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
