# Tests for ct_prop
# Generated using metadata-based test generator
# Return type: list
# A list or dataframe


test_that("ct_prop works without parameters", {
    vcr::use_cassette("ct_prop_basic", {
        result <- ct_prop()
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})
