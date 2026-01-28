# Tests for ct_exposure_product-data_puc
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_product-data_puc works without parameters", {
    vcr::use_cassette("ct_exposure_product-data_puc_basic", {
        result <- `ct_exposure_product-data_puc`()
        {
            expect_true(!is.null(result))
        }
    })
})
