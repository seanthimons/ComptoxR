# Tests for ct_chemical_search_equal
# Generated using metadata-based test generator
# Return type: tibble
# A tibble with search results


test_that("ct_chemical_search_equal works with single input", {
    vcr::use_cassette("ct_chemical_search_equal_single", {
        result <- ct_chemical_search_equal(word = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_chemical_search_equal works with documented example", {
    vcr::use_cassette("ct_chemical_search_equal_example", {
        result <- ct_chemical_search_equal_bulk(query = c("DTXSID7020182", "DTXSID9020112"))
        expect_true(!is.null(result))
    })
})

test_that("ct_chemical_search_equal handles batch requests", {
    vcr::use_cassette("ct_chemical_search_equal_batch", {
        result <- ct_chemical_search_equal(word = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_chemical_search_equal handles invalid input gracefully", {
    vcr::use_cassette("ct_chemical_search_equal_error", {
        result <- suppressWarnings(ct_chemical_search_equal(word = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
