# Tests for ct_classify
# Generated using metadata-based test generator
# Return type: unknown
# A dataframe with the original columns plus 'class', 'super_class',


test_that("ct_classify works with single input", {
    vcr::use_cassette("ct_classify_single", {
        result <- ct_classify(df = "DTXSID7020182")
        {
            expect_true(!is.null(result))
        }
    })
})

test_that("ct_classify handles invalid input gracefully", {
    vcr::use_cassette("ct_classify_error", {
        result <- suppressWarnings(ct_classify(df = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
