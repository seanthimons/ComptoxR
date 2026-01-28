# Tests for ct_exposure_list_presence_tags
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_list_presence_tags works without parameters", {
    vcr::use_cassette("ct_exposure_list_presence_tags_basic", {
        result <- ct_exposure_list_presence_tags()
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_exposure_list_presence_tags works with documented example", {
    vcr::use_cassette("ct_exposure_list_presence_tags_example", {
        result <- ct_exposure_list_presence_tags()
        expect_true(!is.null(result))
    })
})
