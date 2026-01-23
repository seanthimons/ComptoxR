# Tests for ct_exposure_mmdb_mediums
# Generated using helper-test-generator.R


test_that("ct_exposure_mmdb_mediums works with valid input", 
    {
        vcr::use_cassette("ct_exposure_mmdb_mediums_query", {
            result <- ct_exposure_mmdb_mediums(query = "DTXSID7020182")
            {
                expect_s3_class(result, "tbl_df")
                expect_true(ncol(result) > 0)
            }
        })
    })

test_that("ct_exposure_mmdb_mediums handles batch requests", 
    {
        vcr::use_cassette("ct_exposure_mmdb_mediums_batch", {
            result <- ct_exposure_mmdb_mediums(query = c("DTXSID7020182", 
            "DTXSID5032381"))
            expect_s3_class(result, "tbl_df")
            expect_true(nrow(result) > 0)
        })
    })

test_that("ct_exposure_mmdb_mediums handles invalid input gracefully", 
    {
        vcr::use_cassette("ct_exposure_mmdb_mediums_error", {
            expect_warning(result <- ct_exposure_mmdb_mediums(query = "INVALID_ID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
