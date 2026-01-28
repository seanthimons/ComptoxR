# Tests for ct_bioactivity_aop_by-toxcast-aeid
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_bioactivity_aop_by-toxcast-aeid works without parameters", {
    vcr::use_cassette("ct_bioactivity_aop_by-toxcast-aeid_basic", {
        result <- `ct_bioactivity_aop_by-toxcast-aeid`()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})
