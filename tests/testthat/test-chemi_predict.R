# Tests for chemi_predict
# Generated using helper-test-generator.R


test_that("chemi_predict works with valid input", {
    vcr::use_cassette("chemi_predict_dtxsid", {
        result <- chemi_predict(query = "DTXSID7020182")
        {
            expect_type(result, "list")
            expect_true(length(result) > 0)
        }
    })
})

test_that("chemi_predict handles batch requests", {
    vcr::use_cassette("chemi_predict_batch", {
        result <- chemi_predict(query = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_type(result, "list")
        expect_true(length(result) > 0)
    })
})

test_that("chemi_predict handles invalid input gracefully", {
    vcr::use_cassette("chemi_predict_error", {
        expect_error(result <- chemi_predict(query = "INVALID_DTXSID"))
    })
})
