# Tests for chemi_amos
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos works with single input", {
    vcr::use_cassette("chemi_amos_single", {
        result <- chemi_amos(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos works with documented example", {
    vcr::use_cassette("chemi_amos_example", {
        result <- chemi_amos(dtxsid = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_amos handles batch requests", {
    vcr::use_cassette("chemi_amos_batch", {
        result <- chemi_amos(dtxsid = c("DTXSID7020182", "DTXSID5032381"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_amos handles invalid input gracefully", {
    vcr::use_cassette("chemi_amos_error", {
        result <- suppressWarnings(chemi_amos(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
