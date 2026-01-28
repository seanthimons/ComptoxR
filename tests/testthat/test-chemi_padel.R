# Tests for chemi_padel
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_padel works with single input", {
    vcr::use_cassette("chemi_padel_single", {
        result <- chemi_padel(smiles = "c1ccccc1")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_padel works with documented example", {
    vcr::use_cassette("chemi_padel_example", {
        result <- chemi_padel(smiles = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_padel handles batch requests", {
    vcr::use_cassette("chemi_padel_batch", {
        result <- chemi_padel(smiles = c("c1ccccc1", "CC(C)O"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_padel handles invalid input gracefully", {
    vcr::use_cassette("chemi_padel_error", {
        result <- suppressWarnings(chemi_padel(smiles = "INVALID_SMILES_XYZ"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
