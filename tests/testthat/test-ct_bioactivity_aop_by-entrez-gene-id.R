# Tests for ct_bioactivity_aop_by-entrez-gene-id
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_bioactivity_aop_by-entrez-gene-id works without parameters", {
    vcr::use_cassette("ct_bioactivity_aop_by-entrez-gene-id_basic", {
        result <- `ct_bioactivity_aop_by-entrez-gene-id`()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})
