# Tests for chemi_stdizer_workflows
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_stdizer_workflows works without parameters", {
    vcr::use_cassette("chemi_stdizer_workflows_basic", {
        result <- chemi_stdizer_workflows()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_stdizer_workflows works with documented example", {
    vcr::use_cassette("chemi_stdizer_workflows_example", {
        result <- chemi_stdizer_workflows()
        expect_true(!is.null(result))
    })
})
