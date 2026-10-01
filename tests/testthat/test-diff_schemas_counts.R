# Maintainer-only: dev/diff_schemas.R is excluded from CRAN source tarballs.
# Guards the count_diff_changes() accumulator that feeds the schema-check
# workflow's breaking/non-breaking outputs. Regression target: sum(sapply())
# over an empty or error-mixed result list aborted with
# "invalid 'type' (list) of argument".

dev_diff_schemas <- testthat::test_path("..", "..", "dev", "diff_schemas.R")

skip_diff <- function() {
  testthat::skip_if_not(
    file.exists(dev_diff_schemas),
    "Maintainer-only test requires dev/diff_schemas.R; dev/ is excluded from CRAN tarballs"
  )
  suppressMessages(source(dev_diff_schemas))
}

test_that("count_diff_changes returns 0/0 for an empty result list", {
  skip_diff()
  expect_identical(count_diff_changes(list()), list(breaking = 0L, nonbreaking = 0L))
})

test_that("scheduled schema comparison excludes local stages and detects new production domains", {
  skip_diff()
  workflow <- yaml::yaml.load(paste(
    readLines(
      testthat::test_path("..", "..", ".github", "workflows", "schema-check.yml"),
      encoding = "UTF-8"
    ),
    collapse = "\n"
  ))
  steps <- workflow$jobs[[1]]$steps
  diff_step <- Filter(function(step) identical(step$id, "diff"), steps)[[1]]
  assignment <- Filter(
    function(expr) is.call(expr) && identical(expr[[1]], as.name("<-")) && identical(expr[[2]], as.name("results")),
    as.list(parse(text = diff_step$run))
  )[[1]]
  root <- tempfile()
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE))
  dir.create(file.path(root, "schema_old"))
  dir.create(file.path(root, "schema"))
  fixture <- list(
    openapi = "3.0.0",
    info = list(title = "Probe", version = "1"),
    paths = list('/probe' = list(get = list(summary = "Probe", responses = list('200' = list(description = "OK")))))
  )
  jsonlite::write_json(fixture, file.path(root, "schema", "chemi-probe-dev.json"), auto_unbox = TRUE)
  jsonlite::write_json(fixture, file.path(root, "schema", "chemi-probe-staging.json"), auto_unbox = TRUE)
  withr::local_dir(root)
  expect_length(eval(assignment), 0L)
  jsonlite::write_json(fixture, "schema/chemi-probe-prod.json", auto_unbox = TRUE)
  result <- eval(assignment)
  expect_named(result, "chemi-probe-prod.json")
  expect_equal(nrow(result[[1]]$added), 1L)
})

test_that("count_diff_changes tallies removed/added/modified correctly", {
  skip_diff()
  results <- list(
    "a.json" = list(
      schema_file = "a.json",
      added = tibble::tibble(route = c("x", "y", "z"), method = "GET"),
      removed = tibble::tibble(route = c("p", "q"), method = "GET"),
      modified = tibble::tibble(breaking = c(TRUE, FALSE, TRUE))
    )
  )
  # breaking = 2 removed + 2 modified-breaking = 4
  # nonbreaking = 3 added + 1 modified-nonbreaking = 4
  expect_identical(count_diff_changes(results), list(breaking = 4L, nonbreaking = 4L))
})

test_that("count_diff_changes handles error entries without crashing", {
  skip_diff()
  empty_added <- tibble::tibble(route = character(), method = character())
  results <- list(
    "ok.json" = list(
      schema_file = "ok.json",
      added = tibble::tibble(route = "x", method = "GET"),
      removed = empty_added,
      modified = tibble::tibble(breaking = logical())
    ),
    "bad.json" = list(schema_file = "bad.json", error = "parse failed")
  )
  # breaking = 0 removed + 1 error = 1 ; nonbreaking = 1 added = 1
  expect_identical(count_diff_changes(results), list(breaking = 1L, nonbreaking = 1L))
})
