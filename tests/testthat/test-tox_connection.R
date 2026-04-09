# Tests for ToxValDB connection infrastructure
# -------------------------------------------------------------------

# Always-run tests (no database required) --------------------------------

test_that("tox_path() returns path ending in toxval.duckdb", {
  path <- tox_path()
  expect_true(grepl("toxval\\.duckdb$", path))
})

test_that("tox_path() respects options(ComptoxR.toxval_path)", {
  withr::with_options(
    list(ComptoxR.toxval_path = "/tmp/custom_toxval.duckdb"),
    {
      expect_equal(tox_path(), "/tmp/custom_toxval.duckdb")
    }
  )
})

test_that(".tox_get_con() aborts when DB missing", {
  withr::with_options(
    list(ComptoxR.toxval_path = "/nonexistent/path/toxval.duckdb"),
    {
      withr::with_envvar(c("tox_burl" = ""), {
        expect_error(.tox_get_con(), "ToxValDB database not found")
      })
    }
  )
})

test_that(".tox_close_con() is safe with no connection", {
  # Should not error even when there's nothing to close
  old <- .ComptoxREnv$toxval_db
  .ComptoxREnv$toxval_db <- NULL
  expect_silent(.tox_close_con())
  .ComptoxREnv$toxval_db <- old
})

test_that("tox_server(NULL) resets tox_burl", {
  old <- Sys.getenv("tox_burl")
  suppressMessages(tox_server(NULL))
  expect_equal(Sys.getenv("tox_burl"), "")
  # Restore
  Sys.setenv("tox_burl" = old)
})

test_that("tox_server(99) warns invalid option", {
  old <- Sys.getenv("tox_burl")
  expect_message(tox_server(99), "Invalid server option")
  # Restore
  Sys.setenv("tox_burl" = old)
})

test_that("tox_server() with nonexistent file path aborts", {
  expect_error(tox_server("/nonexistent.duckdb"), "not found")
})


# Live tests (database required) ------------------------------------------

test_that("connection returns valid DBIConnection", {
  skip_if_not(file.exists(tox_path()), "ToxValDB not installed")

  con <- .tox_get_con()
  expect_true(inherits(con, "DBIConnection"))
  expect_true(DBI::dbIsValid(con))
})

test_that(".tox_get_con() returns same cached connection", {
  skip_if_not(file.exists(tox_path()), "ToxValDB not installed")

  con1 <- .tox_get_con()
  con2 <- .tox_get_con()
  expect_identical(con1, con2)
})

test_that("tox_health() returns expected fields", {
  skip_if_not(file.exists(tox_path()), "ToxValDB not installed")

  health <- tox_health()
  expect_type(health, "list")
  expect_true("status" %in% names(health))
  expect_true("db_path" %in% names(health))
  expect_true("version_label" %in% names(health))
  expect_true("db_size_mb" %in% names(health))
})
