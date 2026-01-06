# Tests for chemi_search
# Generated using helper-test-generator.R


test_that("chemi_search works with valid input", {
    vcr::use_cassette("chemi_search_dtxsid", {
        result <- chemi_search(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("chemi_search handles batch requests", {
    vcr::use_cassette("chemi_search_batch", {
        result <- chemi_search(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("chemi_search handles invalid input gracefully", {
    vcr::use_cassette("chemi_search_error", {
        expect_warning(result <- chemi_search(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
