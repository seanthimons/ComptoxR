# Tests for ct_bioactivity_data_search_by_m4id
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_data_search_by_m4id works with single input", {
    vcr::use_cassette("ct_bioactivity_data_search_by_m4id_single", {
        result <- ct_bioactivity_data_search_by_m4id(m4id = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_bioactivity_data_search_by_m4id works with documented example", {
    vcr::use_cassette("ct_bioactivity_data_search_by_m4id_example", {
        result <- ct_bioactivity_data_search_by_m4id_bulk(query = c("DTXSID7020182", 
            "DTXSID10161156", "DTXSID9020035"))
        expect_true(!is.null(result))
    })
})

test_that("ct_bioactivity_data_search_by_m4id handles batch requests", {
    vcr::use_cassette("ct_bioactivity_data_search_by_m4id_batch", {
        result <- ct_bioactivity_data_search_by_m4id(m4id = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_bioactivity_data_search_by_m4id handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_bioactivity_data_search_by_m4id_error", {
            result <- suppressWarnings(ct_bioactivity_data_search_by_m4id(m4id = "INVALID_DTXSID_12345"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
