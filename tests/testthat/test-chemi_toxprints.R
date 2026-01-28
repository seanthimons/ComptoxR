# Tests for chemi_toxprints
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_toxprints works with single input", {
    vcr::use_cassette("chemi_toxprints_single", {
        result <- chemi_toxprints(smiles = "c1ccccc1")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_toxprints works with documented example", {
    vcr::use_cassette("chemi_toxprints_example", {
        result <- chemi_toxprints(smiles = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_toxprints handles batch requests", {
    vcr::use_cassette("chemi_toxprints_batch", {
        result <- chemi_toxprints(smiles = c("c1ccccc1", "CC(C)O"))
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_toxprints handles invalid input gracefully", {
    vcr::use_cassette("chemi_toxprints_error", {
        result <- suppressWarnings(chemi_toxprints(smiles = "INVALID_SMILES_XYZ"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
