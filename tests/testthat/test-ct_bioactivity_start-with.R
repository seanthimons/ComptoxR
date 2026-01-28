# Tests for ct_bioactivity_start-with
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_start-with works without parameters", {
    vcr::use_cassette("ct_bioactivity_start-with_basic", {
        result <- `ct_bioactivity_start-with`()
        {
            expect_true(!is.null(result))
        }
    })
})
