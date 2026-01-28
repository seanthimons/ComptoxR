# Tests for ct_bioactivity_assay_by-gene
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_assay_by-gene works without parameters", {
    vcr::use_cassette("ct_bioactivity_assay_by-gene_basic", {
        result <- `ct_bioactivity_assay_by-gene`()
        {
            expect_true(!is.null(result))
        }
    })
})
