# Tests for ct_chemical_list_type
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_chemical_list_type works without parameters", {
    vcr::use_cassette("ct_chemical_list_type_basic", {
        result <- ct_chemical_list_type()
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_chemical_list_type works with documented example", {
    vcr::use_cassette("ct_chemical_list_type_example", {
        result <- ct_chemical_list_type()
        expect_true(!is.null(result))
    })
})
