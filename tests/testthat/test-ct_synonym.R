# Tests for ct_synonym
# Generated using metadata-based test generator
# Return type: unknown
# 


test_that("ct_synonym works without parameters", {
    vcr::use_cassette("ct_synonym_basic", {
        result <- ct_synonym()
        {
            expect_true(!is.null(result))
        }
    })
})
