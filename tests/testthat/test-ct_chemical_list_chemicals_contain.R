# Tests for ct_chemical_list_chemicals_contain
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_chemical_list_chemicals_contain works with single input", {
    vcr::use_cassette("ct_chemical_list_chemicals_contain_single", {
        result <- ct_chemical_list_chemicals_contain(list = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_chemical_list_chemicals_contain works with documented example", {
    vcr::use_cassette("ct_chemical_list_chemicals_contain_example", {
        result <- ct_chemical_list_chemicals_contain(list = "40CFR1164")
        expect_true(!is.null(result))
    })
})

test_that("ct_chemical_list_chemicals_contain handles batch requests", {
    vcr::use_cassette("ct_chemical_list_chemicals_contain_batch", {
        result <- ct_chemical_list_chemicals_contain(list = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_chemical_list_chemicals_contain handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_list_chemicals_contain_error", {
            result <- suppressWarnings(ct_chemical_list_chemicals_contain(list = "INVALID_DTXSID_12345"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
