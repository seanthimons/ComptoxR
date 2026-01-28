# Tests for chemi_resolver_ccte_lists
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("chemi_resolver_ccte_lists works without parameters", {
    vcr::use_cassette("chemi_resolver_ccte_lists_basic", {
        result <- chemi_resolver_ccte_lists()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_resolver_ccte_lists works with documented example", {
    vcr::use_cassette("chemi_resolver_ccte_lists_example", {
        result <- chemi_resolver_ccte_lists()
        expect_true(!is.null(result))
    })
})
