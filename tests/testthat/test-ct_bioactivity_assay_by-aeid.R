# Tests for ct_bioactivity_assay_by-aeid
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_assay_by-aeid works without parameters", {
    vcr::use_cassette("ct_bioactivity_assay_by-aeid_basic", {
        result <- `ct_bioactivity_assay_by-aeid`()
        {
            expect_true(!is.null(result))
        }
    })
})
