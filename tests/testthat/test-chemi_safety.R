# Tests for chemi_safety
# Generated using metadata-based test generator
# Return type: list
# A list of data


test_that("chemi_safety works with single input", {
    vcr::use_cassette("chemi_safety_single", {
        result <- chemi_safety(query = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_safety works with documented example", {
    vcr::use_cassette("chemi_safety_example", {
        result <- chemi_safety(query = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_safety handles invalid input gracefully", {
    vcr::use_cassette("chemi_safety_error", {
        result <- suppressWarnings(chemi_safety(query = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
