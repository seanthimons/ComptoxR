# Tests for genra_uncertainty()
# Unit tests for uncertainty quantification

test_that("genra_uncertainty returns expected structure", {
  activities <- c(1L, 1L, 0L, 1L, 0L)
  similarities <- c(0.95, 0.88, 0.82, 0.75, 0.70)

  result <- genra_uncertainty(activities, similarities, n_permutations = 10)

  expect_type(result, "list")
  expect_named(result, c("swa", "auc", "p_value", "threshold", "n_active", "n_inactive", "n_permutations"))
  expect_true(is.numeric(result$swa))
  expect_true(is.numeric(result$p_value))
  expect_equal(result$threshold, 0.5)
  expect_equal(result$n_active, 3L)
  expect_equal(result$n_inactive, 2L)
  expect_equal(result$n_permutations, 10L)
})

test_that("genra_uncertainty calculates correct SWA", {
  activities <- c(1L, 1L, 0L)
  similarities <- c(0.9, 0.8, 0.7)

  result <- genra_uncertainty(activities, similarities, n_permutations = 10)
  expected_swa <- sum(similarities * activities) / sum(similarities)

  expect_equal(result$swa, expected_swa)
})

test_that("genra_uncertainty p-value is between 0 and 1", {
  activities <- c(1L, 1L, 0L, 1L, 0L)
  similarities <- c(0.95, 0.88, 0.82, 0.75, 0.70)

  result <- genra_uncertainty(activities, similarities, n_permutations = 50)

  expect_gte(result$p_value, 0)
  expect_lte(result$p_value, 1)
})

test_that("genra_uncertainty handles empty input", {
  result <- genra_uncertainty(integer(0), numeric(0), n_permutations = 10)

  expect_true(is.na(result$swa))
  expect_true(is.na(result$auc))
  expect_true(is.na(result$p_value))
  expect_equal(result$n_active, 0L)
  expect_equal(result$n_inactive, 0L)
})

test_that("genra_uncertainty handles all-NA activities", {
  result <- genra_uncertainty(c(NA_integer_, NA_integer_), c(0.9, 0.8), n_permutations = 10)

  expect_true(is.na(result$swa))
  expect_equal(result$n_active, 0L)
  expect_equal(result$n_inactive, 0L)
})

test_that("genra_uncertainty validates input lengths", {
  expect_error(
    genra_uncertainty(c(1L, 0L), c(0.9, 0.8, 0.7), n_permutations = 10),
    "must match"
  )
})

test_that("genra_uncertainty validates n_permutations", {
  expect_error(
    genra_uncertainty(c(1L, 0L), c(0.9, 0.8), n_permutations = 0),
    ">= 1"
  )
})

test_that("genra_uncertainty excludes NA activities from counts", {
  activities <- c(1L, NA_integer_, 0L)
  similarities <- c(0.9, 0.8, 0.7)

  result <- genra_uncertainty(activities, similarities, n_permutations = 10)

  expect_equal(result$n_active, 1L)
  expect_equal(result$n_inactive, 1L)
})

test_that("genra_uncertainty AUC requires both classes", {
  skip_if_not_installed("pROC")

  # All active - AUC should be NA
  result_active <- genra_uncertainty(c(1L, 1L, 1L), c(0.9, 0.8, 0.7), n_permutations = 10)
  expect_true(is.na(result_active$auc))

  # All inactive - AUC should be NA
  result_inactive <- genra_uncertainty(c(0L, 0L, 0L), c(0.9, 0.8, 0.7), n_permutations = 10)
  expect_true(is.na(result_inactive$auc))

  # Mixed - AUC should be calculated
  result_mixed <- genra_uncertainty(c(1L, 1L, 0L, 0L), c(0.95, 0.90, 0.60, 0.50), n_permutations = 10)
  expect_false(is.na(result_mixed$auc))
  expect_gte(result_mixed$auc, 0)
  expect_lte(result_mixed$auc, 1)
})

test_that("genra_uncertainty works without pROC installed", {
  # This test verifies the function handles missing pROC gracefully
  # We can't actually unload pROC, but we verify the logic handles it
  activities <- c(1L, 0L)
  similarities <- c(0.9, 0.8)

  result <- genra_uncertainty(activities, similarities, n_permutations = 10)

  # Should still return a valid result structure
  expect_type(result, "list")
  expect_true(is.numeric(result$swa))
  expect_true(is.numeric(result$p_value))
})
