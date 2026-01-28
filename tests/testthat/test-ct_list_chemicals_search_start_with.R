# Tests for ct_list_chemicals_search_start_with
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_list_chemicals_search_start_with works with single input", {
    vcr::use_cassette("ct_list_chemicals_search_start_with_single", {
        result <- ct_list_chemicals_search_start_with(list = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_list_chemicals_search_start_with works with documented example", {
    vcr::use_cassette("ct_list_chemicals_search_start_with_example", {
        result <- ct_list_chemicals_search_start_with(list = "40CFR1164")
        expect_true(!is.null(result))
    })
})

test_that("ct_list_chemicals_search_start_with handles batch requests", {
    vcr::use_cassette("ct_list_chemicals_search_start_with_batch", {
        result <- ct_list_chemicals_search_start_with(list = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_list_chemicals_search_start_with handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_list_chemicals_search_start_with_error", {
            result <- suppressWarnings(ct_list_chemicals_search_start_with(list = "INVALID_DTXSID_12345"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
