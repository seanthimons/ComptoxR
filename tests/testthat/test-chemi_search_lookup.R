# Tests for chemi_search_lookup
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_search_lookup works without parameters", {
    vcr::use_cassette("chemi_search_lookup_basic", {
        result <- chemi_search_lookup()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_search_lookup works with documented example", {
    vcr::use_cassette("chemi_search_lookup_example", {
        result <- chemi_search_lookup()
        expect_true(!is.null(result))
    })
})
