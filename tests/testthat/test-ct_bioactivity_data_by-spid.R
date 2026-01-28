# Tests for ct_bioactivity_data_by-spid
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_data_by-spid works without parameters", {
    vcr::use_cassette("ct_bioactivity_data_by-spid_basic", {
        result <- `ct_bioactivity_data_by-spid`()
        {
            expect_true(!is.null(result))
        }
    })
})
