# Tests for ct_chemical_search_by_exact_formula
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_chemical_search_by_exact_formula works with single input", {
    vcr::use_cassette("ct_chemical_search_by_exact_formula_single", {
        result <- ct_chemical_search_by_exact_formula(formula = "C6H6")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_chemical_search_by_exact_formula works with documented example", {
    vcr::use_cassette("ct_chemical_search_by_exact_formula_example", {
        result <- ct_chemical_search_by_exact_formula(formula = "C15H16O2")
        expect_true(!is.null(result))
    })
})

test_that("ct_chemical_search_by_exact_formula handles batch requests", {
    vcr::use_cassette("ct_chemical_search_by_exact_formula_batch", {
        result <- ct_chemical_search_by_exact_formula(formula = c("C6H6", "C7H8"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_chemical_search_by_exact_formula handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_search_by_exact_formula_error", {
            result <- suppressWarnings(ct_chemical_search_by_exact_formula(formula = "INVALID_FORMULA"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
