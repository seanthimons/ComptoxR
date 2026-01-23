# Tests for ct_schema
# Generated using helper-test-generator.R


test_that("ct_schema works with valid input", {
    vcr::use_cassette("ct_schema_query", {
        result <- ct_schema(query = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("ct_schema handles batch requests", {
    vcr::use_cassette("ct_schema_batch", {
        result <- ct_schema(query = c("DTXSID7020182", "DTXSID5032381"
        ))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("ct_schema handles invalid input gracefully", {
    vcr::use_cassette("ct_schema_error", {
        expect_warning(result <- ct_schema(query = "INVALID_ID"))
        expect_true(is.null(result) || nrow(result) == 0)
    })
})
