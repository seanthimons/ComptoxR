# Tests for chemi_safety_classes
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("chemi_safety_classes works without parameters", {
    vcr::use_cassette("chemi_safety_classes_basic", {
        result <- chemi_safety_classes()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_safety_classes works with documented example", {
    vcr::use_cassette("chemi_safety_classes_example", {
        result <- chemi_safety_classes()
        expect_true(!is.null(result))
    })
})
