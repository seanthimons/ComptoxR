# Tests for chemi_amos_find_dtxsids
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_find_dtxsids works without parameters", {
    vcr::use_cassette("chemi_amos_find_dtxsids_basic", {
        result <- chemi_amos_find_dtxsids()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_find_dtxsids works with documented example", {
    vcr::use_cassette("chemi_amos_find_dtxsids_example", {
        result <- chemi_amos_find_dtxsids()
        expect_true(!is.null(result))
    })
})
