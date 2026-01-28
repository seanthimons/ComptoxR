# Tests for ct_bioactivity_contain
# Generated using metadata-based test generator
# Return type: unknown
# Returns a scalar value


test_that("ct_bioactivity_contain works with single input", {
    vcr::use_cassette("ct_bioactivity_contain_single", {
        result <- ct_bioactivity_contain(value = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_bioactivity_contain works with documented example", {
    vcr::use_cassette("ct_bioactivity_contain_example", {
        result <- ct_bioactivity_contain(value = "DTXSID7020182")
        expect_true(!is.null(result))
    })
})

test_that("ct_bioactivity_contain handles batch requests", {
    vcr::use_cassette("ct_bioactivity_contain_batch", {
        result <- ct_bioactivity_contain(value = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_bioactivity_contain handles invalid input gracefully", {
    vcr::use_cassette("ct_bioactivity_contain_error", {
        result <- suppressWarnings(ct_bioactivity_contain(value = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
