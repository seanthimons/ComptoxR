# Tests for chemi_predict
# Generated using metadata-based test generator
# Return type: list
# A list containing the API response.  Returns NULL if the


test_that("chemi_predict works with single input", {
    vcr::use_cassette("chemi_predict_single", {
        result <- chemi_predict(query = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(is.list(result))
        }
    })
})

test_that("chemi_predict handles invalid input gracefully", {
    vcr::use_cassette("chemi_predict_error", {
        result <- suppressWarnings(chemi_predict(query = "INVALID_DTXSID_12345"))
        expect_true(is.null(result) || (is.data.frame(result) && nrow(result) == 
            0) || (is.character(result) && length(result) == 0) || (is.list(result) && 
            length(result) == 0))
    })
})
