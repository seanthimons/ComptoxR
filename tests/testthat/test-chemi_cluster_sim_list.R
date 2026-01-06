# Tests for chemi_cluster_sim_list
# Generated using helper-test-generator.R


test_that("chemi_cluster_sim_list works with valid input", {
    vcr::use_cassette("chemi_cluster_sim_list_dtxsid", {
        result <- chemi_cluster_sim_list(dtxsid = "DTXSID7020182")
        {
            expect_s3_class(result, "tbl_df")
            expect_true(ncol(result) > 0)
        }
    })
})

test_that("chemi_cluster_sim_list handles batch requests", {
    vcr::use_cassette("chemi_cluster_sim_list_batch", {
        result <- chemi_cluster_sim_list(dtxsid = c("DTXSID7020182", 
        "DTXSID5032381", "DTXSID8024291"))
        expect_s3_class(result, "tbl_df")
        expect_true(nrow(result) > 0)
    })
})

test_that("chemi_cluster_sim_list handles invalid input gracefully", 
    {
        vcr::use_cassette("chemi_cluster_sim_list_error", {
            expect_warning(result <- chemi_cluster_sim_list(dtxsid = "INVALID_DTXSID"))
            expect_true(is.null(result) || nrow(result) == 0)
        })
    })
