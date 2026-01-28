# Tests for chemi_amos_formula
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_amos_formula works with single input", {
    vcr::use_cassette("chemi_amos_formula_single", {
        result <- chemi_amos_formula(formula = "C6H6")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_amos_formula works with documented example", {
    vcr::use_cassette("chemi_amos_formula_example", {
        result <- chemi_amos_formula(formula = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_amos_formula handles batch requests", {
    vcr::use_cassette("chemi_amos_formula_batch", {
        result <- chemi_amos_formula(formula = c("C6H6", "C7H8"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_amos_formula handles invalid input gracefully", {
    vcr::use_cassette("chemi_amos_formula_error", {
        result <- suppressWarnings(chemi_amos_formula(formula = "INVALID_FORMULA"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
