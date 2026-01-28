# Tests for chemi_toxprints_chemicals_categories
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_toxprints_chemicals_categories works with single input", {
    vcr::use_cassette("chemi_toxprints_chemicals_categories_single", {
        result <- chemi_toxprints_chemicals_categories(`chemicals = NULL` = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_toxprints_chemicals_categories works with documented example", {
    vcr::use_cassette("chemi_toxprints_chemicals_categories_example", {
        result <- chemi_toxprints_chemicals_categories(chemicals = c("DTXSID3032040", 
            "DTXSID10894891", "DTXSID90486733"))
        expect_true(!is.null(result))
    })
})

test_that("chemi_toxprints_chemicals_categories handles invalid input gracefully", 
    {
        vcr::use_cassette("chemi_toxprints_chemicals_categories_error", {
            result <- suppressWarnings(chemi_toxprints_chemicals_categories(`chemicals = NULL` = "INVALID_DTXSID_12345"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
