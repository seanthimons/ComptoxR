# Tests for chemi_resolver_getannotationslist
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("chemi_resolver_getannotationslist works with single input", {
    vcr::use_cassette("chemi_resolver_getannotationslist_single", {
        result <- chemi_resolver_getannotationslist(name = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_resolver_getannotationslist works with documented example", {
    vcr::use_cassette("chemi_resolver_getannotationslist_example", {
        result <- chemi_resolver_getannotationslist(name = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_resolver_getannotationslist handles batch requests", {
    vcr::use_cassette("chemi_resolver_getannotationslist_batch", {
        result <- chemi_resolver_getannotationslist(name = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_resolver_getannotationslist handles invalid input gracefully", {
    vcr::use_cassette("chemi_resolver_getannotationslist_error", {
        result <- suppressWarnings(chemi_resolver_getannotationslist(name = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
