# Tests for ct_bioactivity_models
# Generated using metadata-based test generator
# Return type: tibble
# Returns a tibble with results (array of objects)


test_that("ct_bioactivity_models works with single input", {
    vcr::use_cassette("ct_bioactivity_models_single", {
        result <- ct_bioactivity_models(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0 || nrow(result) == 0)
        }
    })
})

test_that("ct_bioactivity_models works with documented example", {
    vcr::use_cassette("ct_bioactivity_models_example", {
        result <- ct_bioactivity_models(dtxsid = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("ct_bioactivity_models handles batch requests", {
    vcr::use_cassette("ct_bioactivity_models_batch", {
        result <- ct_bioactivity_models(dtxsid = c("DTXSID7020182", "DTXSID5032381"
        ))
        {
            expect_s3_class(result, "tbl_df")
            expect_true(is.data.frame(result))
        }
    })
})

test_that("ct_bioactivity_models handles invalid input gracefully", {
    vcr::use_cassette("ct_bioactivity_models_error", {
        result <- suppressWarnings(ct_bioactivity_models(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
