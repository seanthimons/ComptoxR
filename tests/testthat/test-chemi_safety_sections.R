# Tests for chemi_safety_sections
# Generated using metadata-based test generator
# Return type: list
# A list where each element corresponds to a DTXSID in the `query`. Each


test_that("chemi_safety_sections works without parameters", {
    vcr::use_cassette("chemi_safety_sections_basic", {
        result <- chemi_safety_sections()
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})
