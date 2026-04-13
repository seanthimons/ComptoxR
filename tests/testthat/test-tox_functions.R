# Tests for ToxValDB query functions
# -------------------------------------------------------------------

# Always-run tests (no database required) --------------------------------

test_that("toxval_results() aborts when all filters NULL", {
  expect_error(
    toxval_results(),
    "At least one filter parameter must be provided"
  )
})

test_that(".tox_route() returns 'plumber' for localhost URLs", {
  withr::with_envvar(c("toxval_burl" = "http://127.0.0.1:5556"), {
    expect_equal(.tox_route(), "plumber")
  })
})

test_that(".tox_route() aborts for public URLs", {
  withr::with_envvar(c("toxval_burl" = "https://comptox.epa.gov/dashboard"), {
    expect_error(.tox_route(), "no public REST API")
  })
})

test_that(".tox_route() returns 'duckdb' for .duckdb paths", {
  withr::with_envvar(c("toxval_burl" = "/some/path/toxval.duckdb"), {
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

test_that("toxval_results(casrn) returns tibble with default columns", {
  skip_if_not(file.exists(toxval_path()), "ToxValDB not installed")

  result <- toxval_results(casrn = "50-00-0")
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)

  # Should have approximately the default column set
  default_cols <- .tox_default_cols()
  present <- intersect(default_cols, names(result))
  expect_true(length(present) >= 35)
})

test_that("toxval_results(source) filters correctly", {
  skip_if_not(file.exists(toxval_path()), "ToxValDB not installed")

  result <- toxval_results(source = "IRIS")
  expect_s3_class(result, "tbl_df")
  expect_true(all(result$source == "IRIS"))
})

test_that("toxval_results(dtxsid, cols = 'all') returns all columns", {
  skip_if_not(file.exists(toxval_path()), "ToxValDB not installed")

  result <- toxval_results(dtxsid = "DTXSID7020182", cols = "all")
  expect_s3_class(result, "tbl_df")
  # "all" should return substantially more columns than default
  expect_true(ncol(result) > length(.tox_default_cols()))
})

test_that("toxval_sources() returns character vector with known sources", {
  skip_if_not(file.exists(toxval_path()), "ToxValDB not installed")

  sources <- toxval_sources()
  expect_type(sources, "character")
  expect_true(length(sources) > 0)
  # These are well-known ToxValDB sources
  expect_true(any(grepl("IRIS", sources)))
})

test_that("toxval_search() returns non-empty tibble for valid DTXSID", {
  skip_if_not(file.exists(toxval_path()), "ToxValDB not installed")

  result <- toxval_search("DTXSID7020182")
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(result$dtxsid == "DTXSID7020182"))
})

test_that("toxval_search() rejects non-character input", {
  expect_error(toxval_search(123), "non-empty character vector")
  expect_error(toxval_search(character(0)), "non-empty character vector")
  expect_error(toxval_search(""), "non-empty character vector")
})

test_that("toxval_tables() includes expected tables", {
  skip_if_not(file.exists(toxval_path()), "ToxValDB not installed")

  tables <- toxval_tables()
  expect_type(tables, "character")
  expect_true("toxval" %in% tables)
  expect_true("_metadata" %in% tables)
})

test_that("human_eco column absent from v9.7.0 data", {
  skip_if_not(file.exists(toxval_path()), "ToxValDB not installed")

  # human_eco is referenced in toxval_results() but does not exist in v9.7.0.
  # This test documents the known gap. If a future version adds the column,

  # update toxval_results() and flip this expectation.
  fields <- toxval_fields("toxval")
  expect_false("human_eco" %in% fields)
})

test_that("default columns all exist in database", {
  skip_if_not(file.exists(toxval_path()), "ToxValDB not installed")

  fields <- toxval_fields("toxval")
  default_cols <- .tox_default_cols()
  missing <- setdiff(default_cols, fields)
  expect_length(missing, 0)
})

test_that("toxval_results(qc_status = 'all') includes failed records", {
  skip_if_not(file.exists(toxval_path()), "ToxValDB not installed")

  # "all" should return more rows than default "pass_or_not_determined"
  all_res <- toxval_results(source = "IRIS", qc_status = "all")
  filtered_res <- toxval_results(source = "IRIS", qc_status = "pass_or_not_determined")
  expect_true(nrow(all_res) >= nrow(filtered_res))
})
