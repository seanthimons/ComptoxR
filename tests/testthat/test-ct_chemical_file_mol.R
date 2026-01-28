# Tests for ct_chemical_file_mol
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("ct_chemical_file_mol works with single input", {
    vcr::use_cassette("ct_chemical_file_mol_single", {
        result <- ct_chemical_file_mol(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_chemical_file_mol works with documented example", {
    vcr::use_cassette("ct_chemical_file_mol_example", {
        result <- ct_chemical_file_mol(dtxsid = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("ct_chemical_file_mol handles batch requests", {
    vcr::use_cassette("ct_chemical_file_mol_batch", {
        result <- ct_chemical_file_mol(dtxsid = c("DTXSID7020182", "DTXSID5032381"
        ))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_chemical_file_mol handles invalid input gracefully", {
    vcr::use_cassette("ct_chemical_file_mol_error", {
        result <- suppressWarnings(ct_chemical_file_mol(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
