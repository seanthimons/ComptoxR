# Tests for chemi_services_convert
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_services_convert works with single input", {
    vcr::use_cassette("chemi_services_convert_single", {
        result <- chemi_services_convert(`content = NULL` = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_services_convert works with documented example", {
    vcr::use_cassette("chemi_services_convert_example", {
        result <- chemi_services_convert(content = c("DTXSID60160518", "DTXSID2046541", 
            "DTXSID70228451"))
        expect_true(!is.null(result))
    })
})

test_that("chemi_services_convert handles invalid input gracefully", {
    vcr::use_cassette("chemi_services_convert_error", {
        result <- suppressWarnings(chemi_services_convert(`content = NULL` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
