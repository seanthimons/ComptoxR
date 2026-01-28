# Tests for chemi_services_smirks2rxn
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results


test_that("chemi_services_smirks2rxn works with single input", {
    vcr::use_cassette("chemi_services_smirks2rxn_single", {
        result <- chemi_services_smirks2rxn(smirks = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("chemi_services_smirks2rxn works with documented example", {
    vcr::use_cassette("chemi_services_smirks2rxn_example", {
        result <- chemi_services_smirks2rxn(smirks = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("chemi_services_smirks2rxn handles batch requests", {
    vcr::use_cassette("chemi_services_smirks2rxn_batch", {
        result <- chemi_services_smirks2rxn(smirks = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("chemi_services_smirks2rxn handles invalid input gracefully", {
    vcr::use_cassette("chemi_services_smirks2rxn_error", {
        result <- suppressWarnings(chemi_services_smirks2rxn(smirks = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
