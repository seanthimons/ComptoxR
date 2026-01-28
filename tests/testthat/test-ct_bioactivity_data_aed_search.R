# Tests for ct_bioactivity_data_aed_search
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_bioactivity_data_aed_search works with single input", {
    vcr::use_cassette("ct_bioactivity_data_aed_search_single", {
        result <- ct_bioactivity_data_aed_search(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_bioactivity_data_aed_search works with documented example", {
    vcr::use_cassette("ct_bioactivity_data_aed_search_example", {
        result <- ct_bioactivity_data_aed_search_bulk(query = c("DTXSID601026093", 
            "DTXSID30203567", "DTXSID7022883"))
        expect_true(!is.null(result))
    })
})

test_that("ct_bioactivity_data_aed_search handles batch requests", {
    vcr::use_cassette("ct_bioactivity_data_aed_search_batch", {
        result <- ct_bioactivity_data_aed_search(dtxsid = c("DTXSID7020182", "DTXSID5032381"
        ))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_bioactivity_data_aed_search handles invalid input gracefully", {
    vcr::use_cassette("ct_bioactivity_data_aed_search_error", {
        result <- suppressWarnings(ct_bioactivity_data_aed_search(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
