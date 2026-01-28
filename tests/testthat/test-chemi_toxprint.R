# Tests for chemi_toxprint
# Generated using metadata-based test generator
# Return type: unknown
# A dataframe


test_that("chemi_toxprint works with single input", {
    vcr::use_cassette("chemi_toxprint_single", {
        result <- chemi_toxprint(query = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("chemi_toxprint works with documented example", {
    vcr::use_cassette("chemi_toxprint_example", {
        result <- chemi_toxprint(query = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_toxprint handles invalid input gracefully", {
    vcr::use_cassette("chemi_toxprint_error", {
        result <- suppressWarnings(chemi_toxprint(query = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
