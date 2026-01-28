# Tests for ct_exposure_mmdb_aggregate
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_exposure_mmdb_aggregate works with single input", {
    vcr::use_cassette("ct_exposure_mmdb_aggregate_single", {
        result <- ct_exposure_mmdb_aggregate(dtxsid = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_exposure_mmdb_aggregate works with documented example", {
    vcr::use_cassette("ct_exposure_mmdb_aggregate_example", {
        result <- ct_exposure_mmdb_aggregate(dtxsid = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("ct_exposure_mmdb_aggregate handles batch requests", {
    vcr::use_cassette("ct_exposure_mmdb_aggregate_batch", {
        result <- ct_exposure_mmdb_aggregate(dtxsid = c("DTXSID7020182", "DTXSID5032381"
        ))
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_exposure_mmdb_aggregate handles invalid input gracefully", {
    vcr::use_cassette("ct_exposure_mmdb_aggregate_error", {
        result <- suppressWarnings(ct_exposure_mmdb_aggregate(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
