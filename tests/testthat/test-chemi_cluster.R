# Tests for chemi_cluster and chemi_cluster_sim_list
# Custom tests - clustering functions with chemical names

test_that("chemi_cluster creates similarity map from chemical names", {
  vcr::use_cassette("chemi_cluster_basic", {
    # Use chemical names, not DTXSIDs
    chemicals <- c("benzene", "toluene", "xylene")
    result <- chemi_cluster(chemicals, sort = TRUE)

    # Check return type - should be a list
    expect_type(result, "list")

    # Check for expected components
    expect_true("mol_names" %in% names(result))
    expect_true("similarity" %in% names(result))
    expect_true("hc" %in% names(result))

    # mol_names should be a tibble
    expect_s3_class(result$mol_names, "tbl_df")

    # similarity should be a list
    expect_type(result$similarity, "list")

    # hc should be an hclust object
    expect_s3_class(result$hc, "hclust")
  })
})

test_that("chemi_cluster respects hclust_method parameter", {
  vcr::use_cassette("chemi_cluster_method", {
    chemicals <- c("benzene", "toluene")

    # Test with different clustering method
    result <- chemi_cluster(
      chemicals,
      sort = TRUE,
      hclust_method = "average"
    )

    expect_type(result, "list")
    expect_s3_class(result$hc, "hclust")
    expect_equal(result$hc$method, "average")
  })
})

test_that("chemi_cluster requires sort parameter", {
  # sort parameter is required
  expect_error(
    chemi_cluster(c("benzene", "toluene"), sort = NULL),
    "Missing sort"
  )
})

test_that("chemi_cluster handles single chemical", {
  vcr::use_cassette("chemi_cluster_single", {
    result <- chemi_cluster("benzene", sort = TRUE)

    expect_type(result, "list")
    expect_equal(nrow(result$mol_names), 1)
  })
})

test_that("chemi_cluster_sim_list converts cluster data to long format", {
  vcr::use_cassette("chemi_cluster_sim_list", {
    # First create cluster data
    chemicals <- c("benzene", "toluene", "xylene")
    cluster_data <- chemi_cluster(chemicals, sort = TRUE)

    # Then convert to similarity list
    sim_list <- chemi_cluster_sim_list(cluster_data)

    # Check return type
    expect_s3_class(sim_list, "tbl_df")

    # Should have parent, child, and value columns
    expect_true("parent" %in% colnames(sim_list))
    expect_true("child" %in% colnames(sim_list))
    expect_true("value" %in% colnames(sim_list))

    # Should have removed self-comparisons
    expect_false(any(sim_list$parent == sim_list$child))
  })
})

test_that("chemi_cluster_sim_list requires cluster data", {
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
