# Tests for chemi_pfas_atlas
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_pfas_atlas works with single input", {
    vcr::use_cassette("chemi_pfas_atlas_single", {
        result <- chemi_pfas_atlas(smiles = "c1ccccc1")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_pfas_atlas works with documented example", {
    vcr::use_cassette("chemi_pfas_atlas_example", {
        result <- chemi_pfas_atlas(smiles = "Fc1c(F)c(F)c2c(c1F)C(F)(F)C(F)(Br)C2(Cl)Cl")
        expect_true(!is.null(result))
    })
})

test_that("chemi_pfas_atlas handles batch requests", {
    vcr::use_cassette("chemi_pfas_atlas_batch", {
        result <- chemi_pfas_atlas(smiles = c("c1ccccc1", "CC(C)O"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_pfas_atlas handles invalid input gracefully", {
    vcr::use_cassette("chemi_pfas_atlas_error", {
        result <- suppressWarnings(chemi_pfas_atlas(smiles = "INVALID_SMILES_XYZ"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
