# Tests for ct_hazard_skin_eye_search
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_hazard_skin_eye_search works with single input", {
    vcr::use_cassette("ct_hazard_skin_eye_search_single", {
        result <- ct_hazard_skin_eye_search(dtxsid = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_hazard_skin_eye_search works with documented example", {
    vcr::use_cassette("ct_hazard_skin_eye_search_example", {
        result <- ct_hazard_skin_eye_search_bulk(query = c("DTXSID701018815", "DTXSID4023674", 
            "DTXSID6020692"))
        expect_true(!is.null(result))
    })
})

test_that("ct_hazard_skin_eye_search handles batch requests", {
    vcr::use_cassette("ct_hazard_skin_eye_search_batch", {
        result <- ct_hazard_skin_eye_search(dtxsid = c("DTXSID7020182", "DTXSID5032381"
        ))
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_hazard_skin_eye_search handles invalid input gracefully", {
    vcr::use_cassette("ct_hazard_skin_eye_search_error", {
        result <- suppressWarnings(ct_hazard_skin_eye_search(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
