# Tests for ct_exposure_functional_use_category
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_functional_use_category works without parameters", {
    vcr::use_cassette("ct_exposure_functional_use_category_basic", {
        result <- ct_exposure_functional_use_category()
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_exposure_functional_use_category works with documented example", {
    vcr::use_cassette("ct_exposure_functional_use_category_example", {
        result <- ct_exposure_functional_use_category()
        expect_true(!is.null(result))
    })
})
