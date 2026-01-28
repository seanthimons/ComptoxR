# Tests for ct_chemical_file_mol_search_by_dtxcid
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("ct_chemical_file_mol_search_by_dtxcid works with single input", {
    vcr::use_cassette("ct_chemical_file_mol_search_by_dtxcid_single", {
        result <- ct_chemical_file_mol_search_by_dtxcid(dtxcid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_chemical_file_mol_search_by_dtxcid works with documented example", 
    {
        vcr::use_cassette("ct_chemical_file_mol_search_by_dtxcid_example", {
            result <- ct_chemical_file_mol_search_by_dtxcid(dtxcid = "DTXCID505")
            expect_true(!is.null(result))
        })
    })

test_that("ct_chemical_file_mol_search_by_dtxcid handles batch requests", {
    vcr::use_cassette("ct_chemical_file_mol_search_by_dtxcid_batch", {
        result <- ct_chemical_file_mol_search_by_dtxcid(dtxcid = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_chemical_file_mol_search_by_dtxcid handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_chemical_file_mol_search_by_dtxcid_error", {
            result <- suppressWarnings(ct_chemical_file_mol_search_by_dtxcid(dtxcid = "INVALID_DTXSID_12345"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
