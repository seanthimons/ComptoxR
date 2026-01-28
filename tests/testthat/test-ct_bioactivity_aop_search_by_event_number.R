# Tests for ct_bioactivity_aop_search_by_event_number
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_bioactivity_aop_search_by_event_number works with single input", {
    vcr::use_cassette("ct_bioactivity_aop_search_by_event_number_single", {
        result <- ct_bioactivity_aop_search_by_event_number(eventNumber = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_bioactivity_aop_search_by_event_number works with documented example", 
    {
        vcr::use_cassette("ct_bioactivity_aop_search_by_event_number_example", {
            result <- ct_bioactivity_aop_search_by_event_number(eventNumber = "18")
            expect_true(!is.null(result))
        })
    })

test_that("ct_bioactivity_aop_search_by_event_number handles batch requests", {
    vcr::use_cassette("ct_bioactivity_aop_search_by_event_number_batch", {
        result <- ct_bioactivity_aop_search_by_event_number(eventNumber = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_bioactivity_aop_search_by_event_number handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_bioactivity_aop_search_by_event_number_error", {
            result <- suppressWarnings(ct_bioactivity_aop_search_by_event_number(eventNumber = "INVALID_DTXSID_12345"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
