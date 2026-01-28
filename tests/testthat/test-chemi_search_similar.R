# Tests for chemi_search_similar
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_search_similar works with single input", {
    vcr::use_cassette("chemi_search_similar_single", {
        result <- chemi_search_similar(smiles = "c1ccccc1")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_search_similar works with documented example", {
    vcr::use_cassette("chemi_search_similar_example", {
        result <- chemi_search_similar(smiles = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_search_similar handles batch requests", {
    vcr::use_cassette("chemi_search_similar_batch", {
        result <- chemi_search_similar(smiles = c("c1ccccc1", "CC(C)O"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_search_similar handles invalid input gracefully", {
    vcr::use_cassette("chemi_search_similar_error", {
        result <- suppressWarnings(chemi_search_similar(smiles = "INVALID_SMILES_XYZ"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
