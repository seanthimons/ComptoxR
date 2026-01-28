# Tests for chemi_toxprints_assays_check
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_toxprints_assays_check works with single input", {
    vcr::use_cassette("chemi_toxprints_assays_check_single", {
        result <- chemi_toxprints_assays_check(name = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_toxprints_assays_check works with documented example", {
    vcr::use_cassette("chemi_toxprints_assays_check_example", {
        result <- chemi_toxprints_assays_check(name = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_toxprints_assays_check handles batch requests", {
    vcr::use_cassette("chemi_toxprints_assays_check_batch", {
        result <- chemi_toxprints_assays_check(name = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_toxprints_assays_check handles invalid input gracefully", {
    vcr::use_cassette("chemi_toxprints_assays_check_error", {
        result <- suppressWarnings(chemi_toxprints_assays_check(name = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
