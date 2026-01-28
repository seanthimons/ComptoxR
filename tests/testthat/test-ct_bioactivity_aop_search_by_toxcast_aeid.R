# Tests for ct_bioactivity_aop_search_by_toxcast_aeid
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_bioactivity_aop_search_by_toxcast_aeid works with single input", {
    vcr::use_cassette("ct_bioactivity_aop_search_by_toxcast_aeid_single", {
        result <- ct_bioactivity_aop_search_by_toxcast_aeid(toxcastAeid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_bioactivity_aop_search_by_toxcast_aeid works with documented example", 
    {
        vcr::use_cassette("ct_bioactivity_aop_search_by_toxcast_aeid_example", {
            result <- ct_bioactivity_aop_search_by_toxcast_aeid(toxcastAeid = "63")
            expect_true(!is.null(result))
        })
    })

test_that("ct_bioactivity_aop_search_by_toxcast_aeid handles batch requests", {
    vcr::use_cassette("ct_bioactivity_aop_search_by_toxcast_aeid_batch", {
        result <- ct_bioactivity_aop_search_by_toxcast_aeid(toxcastAeid = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_bioactivity_aop_search_by_toxcast_aeid handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_bioactivity_aop_search_by_toxcast_aeid_error", {
            result <- suppressWarnings(ct_bioactivity_aop_search_by_toxcast_aeid(toxcastAeid = "INVALID_DTXSID_12345"))
            expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
                0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
                length(result) == 0))
        })
    })
