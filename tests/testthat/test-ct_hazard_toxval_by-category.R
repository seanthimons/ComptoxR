# Tests for ct_hazard_toxval_by-category
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_hazard_toxval_by-category works without parameters", {
    vcr::use_cassette("ct_hazard_toxval_by-category_basic", {
        result <- `ct_hazard_toxval_by-category`()
        {
            expect_true(!is.null(result))
        }
    })
})
