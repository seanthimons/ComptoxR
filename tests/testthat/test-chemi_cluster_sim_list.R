# Tests for chemi_cluster_sim_list
# This file contains additional tests for chemi_cluster_sim_list
# Main tests are in test-chemi_cluster.R

# Note: chemi_cluster_sim_list takes the output of chemi_cluster,
# not DTXSIDs directly. See test-chemi_cluster.R for complete tests.

test_that("chemi_cluster_sim_list requires chemi_cluster_data parameter", {
    # Should error if no data provided
    expect_error(
        chemi_cluster_sim_list(NULL),
        "Missing chemi_cluster_data"
    )
    
    expect_error(
        chemi_cluster_sim_list(),
        "Missing chemi_cluster_data"
    )
})
