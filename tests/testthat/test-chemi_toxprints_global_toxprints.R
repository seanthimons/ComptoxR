# Tests for chemi_toxprints_global_toxprints
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_toxprints_global_toxprints works with single input", {
    vcr::use_cassette("chemi_toxprints_global_toxprints_single", {
        result <- chemi_toxprints_global_toxprints(`category = NULL` = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_toxprints_global_toxprints works with documented example", {
    vcr::use_cassette("chemi_toxprints_global_toxprints_example", {
        result <- chemi_toxprints_global_toxprints(category = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_toxprints_global_toxprints handles batch requests", {
    vcr::use_cassette("chemi_toxprints_global_toxprints_batch", {
        result <- chemi_toxprints_global_toxprints(`category = NULL` = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_toxprints_global_toxprints handles invalid input gracefully", {
    vcr::use_cassette("chemi_toxprints_global_toxprints_error", {
        result <- suppressWarnings(chemi_toxprints_global_toxprints(`category = NULL` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
