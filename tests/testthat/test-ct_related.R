# Tests for ct_related
# Generated using metadata-based test generator
# Return type: list
# A list of data frames containing related substances.


test_that("ct_related works with single input", {
    vcr::use_cassette("ct_related_single", {
        result <- ct_related(query = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("ct_related works with documented example", {
    vcr::use_cassette("ct_related_example", {
        result <- ct_related(query = "DTXSID0024842")
        expect_true(!is.null(result))
    })
})

test_that("ct_related handles invalid input gracefully", {
    vcr::use_cassette("ct_related_error", {
        result <- suppressWarnings(ct_related(query = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
