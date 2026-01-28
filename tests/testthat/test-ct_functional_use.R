# Tests for ct_functional_use
# Generated using metadata-based test generator
# Return type: tibble
# Tibble or list of tibbles


test_that("ct_functional_use works with single input", {
    vcr::use_cassette("ct_functional_use_single", {
        result <- ct_functional_use(`ct_functional_use <- function(` = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_functional_use handles batch requests", {
    vcr::use_cassette("ct_functional_use_batch", {
        result <- ct_functional_use(`ct_functional_use <- function(` = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_functional_use handles invalid input gracefully", {
    vcr::use_cassette("ct_functional_use_error", {
        result <- suppressWarnings(ct_functional_use(`ct_functional_use <- function(` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
