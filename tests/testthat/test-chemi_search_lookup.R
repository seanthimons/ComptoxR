# Tests for chemi_search_lookup
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_search_lookup works with single input", {
    vcr::use_cassette("chemi_search_lookup_single", {
        result <- chemi_search_lookup(`searchType = NULL` = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_search_lookup works with documented example", {
    vcr::use_cassette("chemi_search_lookup_example", {
        result <- chemi_search_lookup(searchType = c("DTXSID3032040", "DTXSID9025326", 
            "DTXSID6034479"))
        expect_true(!is.null(result))
    })
})

test_that("chemi_search_lookup handles invalid input gracefully", {
    vcr::use_cassette("chemi_search_lookup_error", {
        result <- suppressWarnings(chemi_search_lookup(`searchType = NULL` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
