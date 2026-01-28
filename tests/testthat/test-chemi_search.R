# Tests for chemi_search
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_search works with single input", {
    vcr::use_cassette("chemi_search_single", {
        result <- chemi_search(`searchType = NULL` = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_search works with documented example", {
    vcr::use_cassette("chemi_search_example", {
        result <- chemi_search(searchType = c("DTXSID2033314", "DTXSID50474898", 
            "DTXSID40893599"))
        expect_true(!is.null(result))
    })
})

test_that("chemi_search handles invalid input gracefully", {
    vcr::use_cassette("chemi_search_error", {
        result <- suppressWarnings(chemi_search(`searchType = NULL` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
