# Tests for chemi_toxprints_enrichments
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_toxprints_enrichments works without parameters", {
    vcr::use_cassette("chemi_toxprints_enrichments_basic", {
        result <- chemi_toxprints_enrichments()
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_toxprints_enrichments works with documented example", {
    vcr::use_cassette("chemi_toxprints_enrichments_example", {
        result <- chemi_toxprints_enrichments()
        expect_true(!is.null(result))
    })
})
