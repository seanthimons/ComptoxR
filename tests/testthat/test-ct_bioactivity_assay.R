# Tests for ct_bioactivity_assay
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_assay works with single input", {
    vcr::use_cassette("ct_bioactivity_assay_single", {
        result <- ct_bioactivity_assay(`projection = "assay-all"` = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_bioactivity_assay works with documented example", {
    vcr::use_cassette("ct_bioactivity_assay_example", {
        result <- ct_bioactivity_assay(projection = "assay-all")
        expect_true(!is.null(result))
    })
})

test_that("ct_bioactivity_assay handles batch requests", {
    vcr::use_cassette("ct_bioactivity_assay_batch", {
        result <- ct_bioactivity_assay(`projection = "assay-all"` = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_bioactivity_assay handles invalid input gracefully", {
    vcr::use_cassette("ct_bioactivity_assay_error", {
        result <- suppressWarnings(ct_bioactivity_assay(`projection = "assay-all"` = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
