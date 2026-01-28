# Tests for chemi_toxprints_toxprints_categories
# Generated using metadata-based test generator
# Return type: list
# Returns a list with result object


test_that("chemi_toxprints_toxprints_categories works without parameters", {
    vcr::use_cassette("chemi_toxprints_toxprints_categories_basic", {
        result <- chemi_toxprints_toxprints_categories()
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_toxprints_toxprints_categories works with documented example", {
    vcr::use_cassette("chemi_toxprints_toxprints_categories_example", {
        result <- chemi_toxprints_toxprints_categories()
        expect_true(!is.null(result))
    })
})
