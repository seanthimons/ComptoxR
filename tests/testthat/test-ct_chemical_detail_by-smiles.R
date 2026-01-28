# Tests for ct_chemical_detail_by-smiles
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_chemical_detail_by-smiles works without parameters", {
    vcr::use_cassette("ct_chemical_detail_by-smiles_basic", {
        result <- `ct_chemical_detail_by-smiles`()
        {
            expect_true(!is.null(result))
        }
    })
})
