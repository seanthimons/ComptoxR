# Tests for ct_descriptors
# Generated using helper-test-generator.R


test_that("ct_descriptors works with valid input", {
    vcr::use_cassette("ct_descriptors_query", {
        result <- ct_descriptors(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_descriptors handles batch requests", {
    vcr::use_cassette("ct_descriptors_batch", {
        result <- ct_descriptors(query = c("DTXSID7020182", "DTXSID5032381"
        ))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_descriptors handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_descriptors_error", {
            expect_warning(result <- ct_descriptors(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
