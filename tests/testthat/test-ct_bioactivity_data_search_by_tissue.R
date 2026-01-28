# Tests for ct_bioactivity_data_search_by_tissue
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_data_search_by_tissue works with single input", {
    vcr::use_cassette("ct_bioactivity_data_search_by_tissue_single", {
        result <- ct_bioactivity_data_search_by_tissue(dtxsid = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_bioactivity_data_search_by_tissue works with documented example", {
    vcr::use_cassette("ct_bioactivity_data_search_by_tissue_example", {
        result <- ct_bioactivity_data_search_by_tissue(dtxsid = "DTXSID7024241")
        expect_true(!is.null(result))
    })
})

test_that("ct_bioactivity_data_search_by_tissue handles batch requests", {
    vcr::use_cassette("ct_bioactivity_data_search_by_tissue_batch", {
        result <- ct_bioactivity_data_search_by_tissue(dtxsid = c("DTXSID7020182", 
        "DTXSID5032381"))
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_bioactivity_data_search_by_tissue handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_bioactivity_data_search_by_tissue_error", {
            result <- suppressWarnings(ct_bioactivity_data_search_by_tissue(dtxsid = "INVALID_DTXSID"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
