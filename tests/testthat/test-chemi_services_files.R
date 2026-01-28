# Tests for chemi_services_files
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_services_files works with single input", {
    vcr::use_cassette("chemi_services_files_single", {
        result <- chemi_services_files(`request.filesInfo = NULL` = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_services_files works with documented example", {
    vcr::use_cassette("chemi_services_files_example", {
        result <- chemi_services_files(request.filesInfo = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_services_files handles invalid input gracefully", {
    vcr::use_cassette("chemi_services_files_error", {
        result <- suppressWarnings(chemi_services_files(`request.filesInfo = NULL` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
