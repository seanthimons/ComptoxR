# Tests for ct_hazard_hawc
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_hazard_hawc works with single input", {
    vcr::use_cassette("ct_hazard_hawc_single", {
        result <- ct_hazard_hawc(dtxsid = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_hazard_hawc works with documented example", {
    vcr::use_cassette("ct_hazard_hawc_example", {
        result <- ct_hazard_hawc(dtxsid = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("ct_hazard_hawc handles batch requests", {
    vcr::use_cassette("ct_hazard_hawc_batch", {
        result <- ct_hazard_hawc(dtxsid = c("DTXSID7020182", "DTXSID5032381"))
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_hazard_hawc handles invalid input gracefully", {
    vcr::use_cassette("ct_hazard_hawc_error", {
        result <- suppressWarnings(ct_hazard_hawc(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
