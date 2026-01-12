# Tests for ct_list
# Generated using helper-test-generator.R


test_that("ct_list works with valid input", {
    vcr::use_cassette("ct_list_listname", {
        result <- ct_list(listname = "PRODWATER")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

NULL

test_that("ct_list handles invalid input gracefully", {
    vcr::use_cassette("ct_list_error", {
        expect_warning(result <- ct_list(listname = "NONEXISTENT_LIST"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
