# Tests for ct_bioactivity_assay_count
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_assay_count works without parameters", {
    vcr::use_cassette("ct_bioactivity_assay_count_basic", {
        result <- ct_bioactivity_assay_count()
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_bioactivity_assay_count works with documented example", {
    vcr::use_cassette("ct_bioactivity_assay_count_example", {
        result <- ct_bioactivity_assay_count()
        expect_true(!is.null(result))
    })
})
