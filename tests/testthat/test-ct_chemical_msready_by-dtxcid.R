# Tests for ct_chemical_msready_by-dtxcid
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_chemical_msready_by-dtxcid works without parameters", {
    vcr::use_cassette("ct_chemical_msready_by-dtxcid_basic", {
        result <- `ct_chemical_msready_by-dtxcid`()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})
