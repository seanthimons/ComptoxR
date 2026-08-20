# Maintainer-only: dev/stub_specs.R is excluded from CRAN source tarballs.
# Covers the operation-level coverage helpers that feed calculate_coverage.R.
# Regression target: coverage used to count all ct_/chemi_ function definitions
# against endpoints, so the ratio exceeded 100% and was clamped to a constant
# 100.0%. Coverage is now covered-operations / total-operations, a subset over
# its superset, so it can never exceed 100%.

dev_stub_specs <- testthat::test_path("..", "..", "dev", "stub_specs.R")

skip_specs <- function() {
  testthat::skip_if_not(
    file.exists(dev_stub_specs),
    "Maintainer-only test requires dev/stub_specs.R; dev/ is excluded from CRAN tarballs"
  )
  suppressWarnings(suppressMessages(source(dev_stub_specs)))
}

test_that("is_operation_implemented distinguishes fn within a shared file", {
  skip_specs()
  tmp <- withr::local_tempdir()
  # One file defining the GET wrapper but not the POST (_bulk) wrapper.
  writeLines(
    c("ct_foo <- function(query) {", "  invisible(query)", "}"),
    file.path(tmp, "ct_foo.R")
  )

  expect_true(is_operation_implemented("ct_foo.R", "ct_foo", tmp))
  expect_false(is_operation_implemented("ct_foo.R", "ct_foo_bulk", tmp)) # same file, other op
  expect_false(is_operation_implemented("ct_missing.R", "ct_missing", tmp)) # no file
})

test_that("endpoint_coverage counts operations per (route, method) row", {
  skip_specs()
  tmp <- withr::local_tempdir()
  writeLines("ct_foo <- function(query) query", file.path(tmp, "ct_foo.R"))

  # GET + POST on one route share ct_foo.R; only the GET fn is defined.
  fake_spec <- list(
    build_endpoints = function() {
      tibble::tibble(
        route = c("foo", "foo"),
        method = c("GET", "POST"),
        file = c("ct_foo.R", "ct_foo.R"),
        fn = c("ct_foo", "ct_foo_bulk")
      )
    }
  )

  cov <- endpoint_coverage(fake_spec, pkg_dir = tmp)
  expect_identical(cov, list(total = 2L, covered = 1L))
})

test_that("generation and coverage identify the same missing shared-route operation", {
  skip_specs()
  tmp <- withr::local_tempdir()
  writeLines("ct_foo <- function(query) query", file.path(tmp, "ct_foo.R"))

  endpoints <- tibble::tibble(
    route = c("foo", "foo"),
    method = c("GET", "POST"),
    file = c("ct_foo.R", "ct_foo.R"),
    fn = c("ct_foo", "ct_foo_bulk")
  )
  fake_spec <- list(
    prefix = "ct",
    heading = "Test",
    config = list(),
    build_endpoints = function() endpoints
  )
  selected <- NULL
  rlang::local_bindings(
    find_endpoint_usages_base = function(...) {
      list(summary = tibble::tibble(endpoint = "foo", n_hits = 1L))
    },
    detect_parameter_drift = function(...) tibble::tibble(),
    render_endpoint_stubs = function(endpoints, config) {
      selected <<- endpoints
      tibble::tibble(file = endpoints$file, fn = endpoints$fn, text = "stub")
    },
    scaffold_files = function(...) empty_scaffold(),
    .env = environment(run_generator)
  )

  run_generator(fake_spec, pkg_dir = tmp)
  cov <- endpoint_coverage(fake_spec, pkg_dir = tmp)

  expect_identical(selected$fn, "ct_foo_bulk")
  expect_identical(cov, list(total = 2L, covered = 1L))
})

test_that("endpoint_coverage returns 0/0 for an empty spec", {
  skip_specs()
  empty_spec <- list(build_endpoints = function() tibble::tibble())
  expect_identical(endpoint_coverage(empty_spec), list(total = 0L, covered = 0L))
})

test_that("real ct_/chemi_ coverage is a subset ratio (<= 100%)", {
  skip_specs()
  for (spec in list(ct_spec, chemi_spec)) {
    cov <- suppressWarnings(suppressMessages(endpoint_coverage(spec)))
    expect_gt(cov$total, 0)
    expect_lte(cov$covered, cov$total) # subset => ratio never exceeds 100%
  }
})
