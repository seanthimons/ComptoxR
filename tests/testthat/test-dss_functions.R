# Tests for DSSTox local database functions
# ==========================================

# -- Always-run tests (no database needed) ----------------------------------

test_that("dss_path() returns correct default path", {
  withr::with_options(list(ComptoxR.dsstox_path = NULL), {
    path <- dss_path()
    expect_true(grepl("ComptoxR", path))
    expect_true(grepl("dsstox\\.duckdb$", path))
  })
})

test_that("dss_path() respects ComptoxR.dsstox_path option", {
  withr::with_options(list(ComptoxR.dsstox_path = "/tmp/custom.duckdb"), {
    expect_equal(dss_path(), "/tmp/custom.duckdb")
  })
})

test_that("dss_get_con() aborts with helpful message when DB missing", {
  withr::with_options(list(ComptoxR.dsstox_path = "/nonexistent/path/nope.duckdb"), {
    # Clear cached connection
    old_con <- .ComptoxREnv$dsstox_db
    .ComptoxREnv$dsstox_db <- NULL
    on.exit(.ComptoxREnv$dsstox_db <- old_con, add = TRUE)

    expect_error(dss_get_con(), "not found")
  })
})

test_that("dss_search() rejects invalid cols values", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  expect_error(dss_search("test%", cols = "EVIL_COL"), "Invalid column")
  expect_error(dss_search("test%", cols = c("CASRN", "DROP_TABLE")), "Invalid column")
})

test_that("dss_fuzzy() rejects invalid cols values", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  expect_error(dss_fuzzy("test", cols = "EVIL_COL"), "Invalid column")
})

test_that("dss_fuzzy() validates query type", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  expect_error(dss_fuzzy(""), "non-empty")
  expect_error(dss_fuzzy(123), "non-empty")
  expect_error(dss_fuzzy(c("a", "b")), "non-empty")
})

# -- Live tests (require database) ------------------------------------------

test_that("dss_query() returns results for known chemical", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_query("Formaldehyde")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true("DTXSID" %in% names(result))
})

test_that("dss_synonyms() returns tibble with expected columns", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_synonyms("DTXSID7020637")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true(all(c("DTXSID", "parent_col", "values") %in% names(result)))
})

test_that("dss_synonyms() handles vector input", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_synonyms(c("DTXSID7020637", "DTXSID7020182"))
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  # Should have results for both DTXSIDs
  expect_true(all(c("DTXSID7020637", "DTXSID7020182") %in% result$DTXSID))
})

test_that("dss_resolve() returns DTXSID and PREFERRED_NAME", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_resolve(c("50-00-0", "DTXSID7020637"))
  expect_s3_class(result, "tbl_df")
  expect_true(all(c("input", "DTXSID", "PREFERRED_NAME", "CASRN") %in% names(result)))
  expect_gt(nrow(result), 0)
})

test_that("dss_cas() returns DTXSID for CAS number", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_cas("50-00-0")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true("DTXSID" %in% names(result))
})

test_that("dss_search() returns limited results", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_search("Benz%", limit = 10)
  expect_s3_class(result, "tbl_df")
  expect_lte(nrow(result), 10)
  expect_gt(nrow(result), 0)
})

test_that("dss_fuzzy() returns similarity scores in [0,1]", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")
  result <- dss_fuzzy("Atrazine")
  expect_s3_class(result, "tbl_df")
  expect_gt(nrow(result), 0)
  expect_true("similarity" %in% names(result))
  expect_true(all(result$similarity >= 0 & result$similarity <= 1))
})

test_that("dss_connect() / dss_disconnect() lifecycle works", {
  skip_if_not(file.exists(dss_path()), "DSSTox database not installed")

  # Disconnect any existing connection first
  old_con <- .ComptoxREnv$dsstox_db
  .ComptoxREnv$dsstox_db <- NULL

  con <- dss_connect()
  expect_true(DBI::dbIsValid(con))

  dss_disconnect()
  expect_null(.ComptoxREnv$dsstox_db)

  # Restore
  .ComptoxREnv$dsstox_db <- old_con
})
