# Tests for genra_swa()
# Unit tests for Similarity-Weighted Activity calculation

test_that("genra_swa calculates correct weighted average", {
  # Simple case: all active
  expect_equal(genra_swa(c(1L, 1L, 1L), c(0.9, 0.8, 0.7)), 1.0)

  # Simple case: all inactive
  expect_equal(genra_swa(c(0L, 0L, 0L), c(0.9, 0.8, 0.7)), 0.0)

  # Mixed case: manual calculation
  # (0.9*1 + 0.8*1 + 0.7*0) / (0.9 + 0.8 + 0.7) = 1.7 / 2.4 = 0.7083...
  activities <- c(1L, 1L, 0L)
  similarities <- c(0.9, 0.8, 0.7)
  expected <- sum(similarities * activities) / sum(similarities)
  expect_equal(genra_swa(activities, similarities), expected)
})

test_that("genra_swa handles NA activities", {
  # Should exclude NAs from calculation
  activities <- c(1L, NA_integer_, 0L)
  similarities <- c(0.9, 0.8, 0.7)
  # Should use only indices 1 and 3: (0.9*1 + 0.7*0) / (0.9 + 0.7)
  expected <- 0.9 / 1.6
  expect_equal(genra_swa(activities, similarities), expected)
})

test_that("genra_swa returns NA for empty input", {
  expect_true(is.na(genra_swa(integer(0), numeric(0))))
})

test_that("genra_swa returns NA for all-NA activities", {
  expect_true(is.na(genra_swa(c(NA_integer_, NA_integer_), c(0.9, 0.8))))
})

test_that("genra_swa returns NA when sum of similarities is zero", {
  expect_true(is.na(genra_swa(c(1L, 0L), c(0, 0))))
})

test_that("genra_swa validates input lengths", {
  expect_error(
    genra_swa(c(1L, 0L), c(0.9, 0.8, 0.7)),
    "must match"
  )
})

test_that("genra_swa validates similarity range", {
  expect_error(
    genra_swa(c(1L, 0L), c(0.9, 1.5)),
    "between 0 and 1"
  )
  expect_error(
    genra_swa(c(1L, 0L), c(-0.1, 0.8)),
    "between 0 and 1"
  )
})

test_that("genra_swa validates activity values", {
  expect_error(
    genra_swa(c(1L, 2L), c(0.9, 0.8)),
    "must be 0, 1, or NA"
  )
})

test_that("genra_swa handles single observation", {
  expect_equal(genra_swa(1L, 0.9), 1.0)
  expect_equal(genra_swa(0L, 0.9), 0.0)
})

test_that("genra_swa weights by similarity correctly", {
  # Higher similarity to active should give higher SWA
  # Case 1: high similarity to active
  swa1 <- genra_swa(c(1L, 0L), c(0.95, 0.50))
  # Case 2: high similarity to inactive
  swa2 <- genra_swa(c(1L, 0L), c(0.50, 0.95))

  expect_gt(swa1, swa2)
})
