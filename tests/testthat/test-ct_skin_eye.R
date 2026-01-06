# Tests for ct_skin_eye
# Generated using helper-test-generator.R


test_that("ct_skin_eye works with valid input", {
    vcr::use_cassette("ct_skin_eye_dtxsid", {
        result <- ct_skin_eye(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_skin_eye handles batch requests", {
    vcr::use_cassette("ct_skin_eye_batch", {
        result <- ct_skin_eye(dtxsid = c("DTXSID7020182", "DTXSID5032381", 
        "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_skin_eye handles invalid input gracefully", {
    vcr::use_cassette("ct_skin_eye_error", {
        expect_warning(result <- ct_skin_eye(dtxsid = "INVALID_DTXSID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
