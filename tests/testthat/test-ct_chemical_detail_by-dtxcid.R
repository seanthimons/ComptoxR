# Tests for ct_chemical_detail_by-dtxcid
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_detail_by-dtxcid works without parameters", {
    vcr::use_cassette("ct_chemical_detail_by-dtxcid_basic", {
        result <- `ct_chemical_detail_by-dtxcid`()
        {
            expect_true(!is.null(result))
        }
    })
})
