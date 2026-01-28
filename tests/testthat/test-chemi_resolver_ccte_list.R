# Tests for chemi_resolver_ccte_list
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("chemi_resolver_ccte_list works with single input", {
    vcr::use_cassette("chemi_resolver_ccte_list_single", {
        result <- chemi_resolver_ccte_list(name = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_resolver_ccte_list works with documented example", {
    vcr::use_cassette("chemi_resolver_ccte_list_example", {
        result <- chemi_resolver_ccte_list(name = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_resolver_ccte_list handles batch requests", {
    vcr::use_cassette("chemi_resolver_ccte_list_batch", {
        result <- chemi_resolver_ccte_list(name = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_resolver_ccte_list handles invalid input gracefully", {
    vcr::use_cassette("chemi_resolver_ccte_list_error", {
        result <- suppressWarnings(chemi_resolver_ccte_list(name = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
