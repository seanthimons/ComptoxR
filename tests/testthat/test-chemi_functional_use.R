# Tests for chemi_functional_use
# Generated using metadata-based test generator
# Return type: tibble
# A `tibble` containing the aggregated functional use data


test_that("chemi_functional_use works with single input", {
    vcr::use_cassette("chemi_functional_use_single", {
        result <- chemi_functional_use(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_functional_use handles invalid input gracefully", {
    vcr::use_cassette("chemi_functional_use_error", {
        result <- suppressWarnings(chemi_functional_use(query = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
