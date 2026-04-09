# Tests for ToxValDB query functions
# -------------------------------------------------------------------

# Always-run tests (no database required) --------------------------------

test_that("tox_results() aborts when all filters NULL", {
  expect_error(
    tox_results(),
    "At least one filter parameter must be provided"
  )
})

test_that(".tox_route() returns 'plumber' for localhost URLs", {
  withr::with_envvar(c("tox_burl" = "http://127.0.0.1:5556"), {
    expect_equal(.tox_route(), "plumber")
  })
})

test_that(".tox_route() aborts for public URLs", {
  withr::with_envvar(c("tox_burl" = "https://comptox.epa.gov/dashboard"), {
    expect_error(.tox_route(), "no public REST API")
  })
})

test_that(".tox_route() returns 'duckdb' for .duckdb paths", {
  withr::with_envvar(c("tox_burl" = "/some/path/toxval.duckdb"), {
    expect_equal(.tox_route(), "duckdb")
  })
})

test_that(".tox_default_cols() returns expected column count", {
  cols <- .tox_default_cols()
  expect_type(cols, "character")
  expect_true(length(cols) >= 40)
  expect_true("dtxsid" %in% cols)
  expect_true("casrn" %in% cols)
  expect_true("source" %in% cols)
  expect_true("toxval_numeric" %in% cols)
})


# Live tests (database required) ------------------------------------------

test_that("tox_results(casrn) returns tibble with default columns", {
  skip_if_not(file.exists(tox_path()), "ToxValDB not installed")

  result <- tox_results(casrn = "50-00-0")
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)

  # Should have approximately the default column set
  default_cols <- .tox_default_cols()
  present <- intersect(default_cols, names(result))
  expect_true(length(present) >= 35)
})

test_that("tox_results(source) filters correctly", {
  skip_if_not(file.exists(tox_path()), "ToxValDB not installed")

  result <- tox_results(source = "IRIS")
  expect_s3_class(result, "tbl_df")
  expect_true(all(result$source == "IRIS"))
})

test_that("tox_results(dtxsid, cols = 'all') returns all columns", {
  skip_if_not(file.exists(tox_path()), "ToxValDB not installed")

  result <- tox_results(dtxsid = "DTXSID7020182", cols = "all")
  expect_s3_class(result, "tbl_df")
  # "all" should return substantially more columns than default
  expect_true(ncol(result) > length(.tox_default_cols()))
})

test_that("tox_sources() returns character vector with known sources", {
  skip_if_not(file.exists(tox_path()), "ToxValDB not installed")

  sources <- tox_sources()
  expect_type(sources, "character")
  expect_true(length(sources) > 0)
  # These are well-known ToxValDB sources
  expect_true(any(grepl("IRIS", sources)))
})

test_that("tox_search() returns non-empty tibble", {
  skip_if_not(file.exists(tox_path()), "ToxValDB not installed")

  result <- tox_search("formaldehyde")
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("tox_tables() includes expected tables", {
  skip_if_not(file.exists(tox_path()), "ToxValDB not installed")

  tables <- tox_tables()
  expect_type(tables, "character")
  expect_true("toxval" %in% tables)
  expect_true("_metadata" %in% tables)
})
