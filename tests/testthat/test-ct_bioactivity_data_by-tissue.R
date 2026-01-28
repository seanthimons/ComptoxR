# Tests for ct_bioactivity_data_by-tissue
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_data_by-tissue works without parameters", {
    vcr::use_cassette("ct_bioactivity_data_by-tissue_basic", {
        result <- `ct_bioactivity_data_by-tissue`()
        {
            expect_true(!is.null(result))
        }
    })
})
