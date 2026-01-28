# Tests for ct_bioactivity_data_by-m4id
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_data_by-m4id works without parameters", {
    vcr::use_cassette("ct_bioactivity_data_by-m4id_basic", {
        result <- `ct_bioactivity_data_by-m4id`()
        {
            expect_true(!is.null(result))
        }
    })
})
