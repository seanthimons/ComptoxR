# Tests for chemi_amos_fact_sheets_for_substance
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_fact_sheets_for_substance works with single input", {
    vcr::use_cassette("chemi_amos_fact_sheets_for_substance_single", {
        result <- chemi_amos_fact_sheets_for_substance(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_fact_sheets_for_substance works with documented example", {
    vcr::use_cassette("chemi_amos_fact_sheets_for_substance_example", {
        result <- chemi_amos_fact_sheets_for_substance(dtxsid = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_amos_fact_sheets_for_substance handles batch requests", {
    vcr::use_cassette("chemi_amos_fact_sheets_for_substance_batch", {
        result <- chemi_amos_fact_sheets_for_substance(dtxsid = c("DTXSID7020182", 
        "DTXSID5032381"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_amos_fact_sheets_for_substance handles invalid input gracefully", 
    {
        vcr::use_cassette("chemi_amos_fact_sheets_for_substance_error", {
            result <- suppressWarnings(chemi_amos_fact_sheets_for_substance(dtxsid = "INVALID_DTXSID"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
