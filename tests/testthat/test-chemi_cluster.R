# Tests for chemi_cluster
# Generated using metadata-based test generator
# Return type: list
# List


test_that("chemi_cluster works with single input", {
    vcr::use_cassette("chemi_cluster_single", {
        result <- chemi_cluster(`chemi_cluster <- function(` = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_cluster handles invalid input gracefully", {
    vcr::use_cassette("chemi_cluster_error", {
        result <- suppressWarnings(chemi_cluster(`chemi_cluster <- function(` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
