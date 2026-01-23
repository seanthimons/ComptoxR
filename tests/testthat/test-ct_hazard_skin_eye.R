# Tests for ct_hazard_skin_eye
# Generated using helper-test-generator.R


test_that("ct_hazard_skin_eye works with valid input", {
    vcr::use_cassette("ct_hazard_skin_eye_query", {
        result <- ct_hazard_skin_eye(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_hazard_skin_eye handles batch requests", {
    vcr::use_cassette("ct_hazard_skin_eye_batch", {
        result <- ct_hazard_skin_eye(query = c("DTXSID7020182", 
        "DTXSID5032381"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_hazard_skin_eye handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_hazard_skin_eye_error", {
            expect_warning(result <- ct_hazard_skin_eye(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
