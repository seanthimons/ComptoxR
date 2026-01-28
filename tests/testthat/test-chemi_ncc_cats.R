# Tests for chemi_ncc_cats
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_ncc_cats works with single input", {
    vcr::use_cassette("chemi_ncc_cats_single", {
        result <- chemi_ncc_cats(smiles = "c1ccccc1")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_ncc_cats works with documented example", {
    vcr::use_cassette("chemi_ncc_cats_example", {
        result <- chemi_ncc_cats(smiles = "C1=CC=CC=C1C(C1C=CC=CC=1)C1C=CC=CC=1")
        expect_true(!is.null(result))
    })
})

test_that("chemi_ncc_cats handles batch requests", {
    vcr::use_cassette("chemi_ncc_cats_batch", {
        result <- chemi_ncc_cats(smiles = c("c1ccccc1", "CC(C)O"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_ncc_cats handles invalid input gracefully", {
    vcr::use_cassette("chemi_ncc_cats_error", {
        result <- suppressWarnings(chemi_ncc_cats(smiles = "INVALID_SMILES_XYZ"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
