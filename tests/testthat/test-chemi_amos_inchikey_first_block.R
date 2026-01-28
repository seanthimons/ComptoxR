# Tests for chemi_amos_inchikey_first_block
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_inchikey_first_block works without parameters", {
    vcr::use_cassette("chemi_amos_inchikey_first_block_basic", {
        result <- chemi_amos_inchikey_first_block()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_inchikey_first_block works with documented example", {
    vcr::use_cassette("chemi_amos_inchikey_first_block_example", {
        result <- chemi_amos_inchikey_first_block()
        expect_true(!is.null(result))
    })
})
