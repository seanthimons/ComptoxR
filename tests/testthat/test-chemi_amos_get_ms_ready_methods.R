# Tests for chemi_amos_get_ms_ready_methods
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_get_ms_ready_methods works with single input", {
    vcr::use_cassette("chemi_amos_get_ms_ready_methods_single", {
        result <- chemi_amos_get_ms_ready_methods(inchikey = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_get_ms_ready_methods works with documented example", {
    vcr::use_cassette("chemi_amos_get_ms_ready_methods_example", {
        result <- chemi_amos_get_ms_ready_methods(inchikey = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_amos_get_ms_ready_methods handles batch requests", {
    vcr::use_cassette("chemi_amos_get_ms_ready_methods_batch", {
        result <- chemi_amos_get_ms_ready_methods(inchikey = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_amos_get_ms_ready_methods handles invalid input gracefully", {
    vcr::use_cassette("chemi_amos_get_ms_ready_methods_error", {
        result <- suppressWarnings(chemi_amos_get_ms_ready_methods(inchikey = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
