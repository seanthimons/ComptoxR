# Tests for ct_bioactivity_assay_by-endpoint
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_assay_by-endpoint works without parameters", {
    vcr::use_cassette("ct_bioactivity_assay_by-endpoint_basic", {
        result <- `ct_bioactivity_assay_by-endpoint`()
        {
            expect_true(!is.null(result))
        }
    })
})
