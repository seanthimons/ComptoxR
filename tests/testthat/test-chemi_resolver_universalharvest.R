# Tests for chemi_resolver_universalharvest
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_resolver_universalharvest works with single input", {
    vcr::use_cassette("chemi_resolver_universalharvest_single", {
        result <- chemi_resolver_universalharvest(`request.info.keyName = NULL` = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_resolver_universalharvest works with documented example", {
    vcr::use_cassette("chemi_resolver_universalharvest_example", {
        result <- chemi_resolver_universalharvest(request.info.keyName = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_resolver_universalharvest handles invalid input gracefully", {
    vcr::use_cassette("chemi_resolver_universalharvest_error", {
        result <- suppressWarnings(chemi_resolver_universalharvest(`request.info.keyName = NULL` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
