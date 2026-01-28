# Tests for chemi_amos_dtxsids_for_functional_use
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_dtxsids_for_functional_use works without parameters", {
    vcr::use_cassette("chemi_amos_dtxsids_for_functional_use_basic", {
        result <- chemi_amos_dtxsids_for_functional_use()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_dtxsids_for_functional_use works with documented example", 
    {
        vcr::use_cassette("chemi_amos_dtxsids_for_functional_use_example", {
            result <- chemi_amos_dtxsids_for_functional_use()
            expect_true(!is.null(result))
        })
    })
