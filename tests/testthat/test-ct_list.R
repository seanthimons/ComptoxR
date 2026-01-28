# Tests for ct_list
# Generated using metadata-based test generator
# Return type: character
# Returns a character vector (if extract_dtxsids=TRUE) or list of results (if FALSE)


test_that("ct_list works with single input", {
    vcr::use_cassette("ct_list_single", {
        result <- ct_list(list_name = "PRODWATER")
        {
            expect_type(result, "character")
            expect_true(is.character(result))
        }
    })
})

test_that("ct_list works with documented example", {
    vcr::use_cassette("ct_list_example", {
        result <- ct_list(list_name = c("PRODWATER", "CWA311HS"), extract_dtxsids = TRUE)
        expect_true(!is.null(result))
    })
})

test_that("ct_list handles batch requests", {
    vcr::use_cassette("ct_list_batch", {
        result <- ct_list(list_name = c("PRODWATER", "CWA311HS"))
        {
            expect_type(result, "character")
            expect_true(is.character(result))
        }
    })
})

test_that("ct_list handles invalid input gracefully", {
    vcr::use_cassette("ct_list_error", {
        result <- suppressWarnings(ct_list(list_name = "NONEXISTENT_LIST_XYZ"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
