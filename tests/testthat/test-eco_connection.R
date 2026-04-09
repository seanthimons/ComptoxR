# Tests for ECOTOX local database connection management
# =====================================================

# -- Always-run tests (no database needed) ----------------------------------

test_that("eco_path() returns correct default path", {
  withr::with_options(list(ComptoxR.ecotox_path = NULL), {
    path <- eco_path()
    expect_true(grepl("ComptoxR", path))
    expect_true(grepl("ecotox\\.duckdb$", path))
  })
})

test_that("eco_path() respects ComptoxR.ecotox_path option", {
  withr::with_options(list(ComptoxR.ecotox_path = "/tmp/custom_ecotox.duckdb"), {
    expect_equal(eco_path(), "/tmp/custom_ecotox.duckdb")
  })
})

test_that(".eco_get_con() aborts when DB missing", {
  withr::with_options(list(ComptoxR.ecotox_path = "/nonexistent/path/nope.duckdb"), {
    old_con <- .ComptoxREnv$ecotox_db
    old_burl <- Sys.getenv("eco_burl")
    .ComptoxREnv$ecotox_db <- NULL
    # Set eco_burl to non-duckdb value so it falls through to eco_path()
    Sys.setenv("eco_burl" = "http://example.com")
    on.exit({
      .ComptoxREnv$ecotox_db <- old_con
      Sys.setenv("eco_burl" = old_burl)
    }, add = TRUE)

    expect_error(.eco_get_con(), "not found")
  })
})

test_that(".eco_close_con() is safe with no connection", {
  old_con <- .ComptoxREnv$ecotox_db
  .ComptoxREnv$ecotox_db <- NULL
  on.exit(.ComptoxREnv$ecotox_db <- old_con, add = TRUE)

  expect_silent(.eco_close_con())
  expect_null(.ComptoxREnv$ecotox_db)
})

test_that("eco_server(NULL) resets eco_burl", {
  old_burl <- Sys.getenv("eco_burl")
  on.exit(Sys.setenv("eco_burl" = old_burl), add = TRUE)

  Sys.setenv("eco_burl" = "http://something")
  suppressMessages(eco_server(NULL))
  expect_equal(Sys.getenv("eco_burl"), "")
})

test_that("eco_server(3) sets EPA public URL", {
  old_burl <- Sys.getenv("eco_burl")
  on.exit(Sys.setenv("eco_burl" = old_burl), add = TRUE)

  suppressMessages(eco_server(3))
  expect_true(grepl("epa\\.gov", Sys.getenv("eco_burl")))
})

test_that("eco_server(2) sets localhost URL", {
  old_burl <- Sys.getenv("eco_burl")
  on.exit(Sys.setenv("eco_burl" = old_burl), add = TRUE)

  suppressMessages(eco_server(2))
  expect_true(grepl("127\\.0\\.0\\.1", Sys.getenv("eco_burl")))
})

test_that("eco_server() with invalid option resets", {
  old_burl <- Sys.getenv("eco_burl")
  on.exit(Sys.setenv("eco_burl" = old_burl), add = TRUE)

  suppressMessages(eco_server(99))
  expect_equal(Sys.getenv("eco_burl"), "")
})

test_that("eco_server() with invalid string path aborts", {
  old_burl <- Sys.getenv("eco_burl")
  on.exit(Sys.setenv("eco_burl" = old_burl), add = TRUE)

  expect_error(
    suppressMessages(eco_server("/nonexistent/fake.duckdb")),
    "not found"
  )
})

test_that("eco_install() aborts when no source provided", {
  # If DB already exists, get "already exists" error; otherwise "source" error
  expect_error(eco_install(), "source|already exists")
})

test_that("eco_install() aborts when source file missing", {
  # If DB already exists, get "already exists" error; otherwise "not found" error
  expect_error(
    eco_install(source = "/nonexistent/ecotox.duckdb"),
    "not found|already exists"
  )
})

# -- Live tests (require database) ------------------------------------------

test_that("eco_server(1) resolves to valid .duckdb path", {
  skip_if_not(file.exists(eco_path()), "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  on.exit(Sys.setenv("eco_burl" = old_burl), add = TRUE)

  suppressMessages(eco_server(1))
  expect_true(grepl("\\.duckdb$", Sys.getenv("eco_burl")))
})

test_that("eco_server() with string path sets eco_burl", {
  skip_if_not(file.exists(eco_path()), "ECOTOX database not installed")
  old_burl <- Sys.getenv("eco_burl")
  on.exit(Sys.setenv("eco_burl" = old_burl), add = TRUE)

  db_path <- eco_path()
  suppressMessages(eco_server(db_path))
  expect_equal(Sys.getenv("eco_burl"), normalizePath(db_path, mustWork = TRUE))
})

test_that(".eco_get_con() returns valid connection", {
  skip_if_not(file.exists(eco_path()), "ECOTOX database not installed")
  old_con <- .ComptoxREnv$ecotox_db
  old_burl <- Sys.getenv("eco_burl")
  on.exit({
    .eco_close_con()
    .ComptoxREnv$ecotox_db <- old_con
    Sys.setenv("eco_burl" = old_burl)
  }, add = TRUE)

  .ComptoxREnv$ecotox_db <- NULL
  suppressMessages(eco_server(1))
  con <- .eco_get_con()
  expect_true(inherits(con, "DBIConnection"))
  expect_true(DBI::dbIsValid(con))
})

test_that(".eco_get_con() reuses cached connection", {
  skip_if_not(file.exists(eco_path()), "ECOTOX database not installed")
  old_con <- .ComptoxREnv$ecotox_db
  old_burl <- Sys.getenv("eco_burl")
  on.exit({
    .eco_close_con()
    .ComptoxREnv$ecotox_db <- old_con
    Sys.setenv("eco_burl" = old_burl)
  }, add = TRUE)

  .ComptoxREnv$ecotox_db <- NULL
  suppressMessages(eco_server(1))
  con1 <- .eco_get_con()
  con2 <- .eco_get_con()
  expect_identical(con1, con2)
})

test_that(".eco_close_con() disconnects and clears cache", {
  skip_if_not(file.exists(eco_path()), "ECOTOX database not installed")
  old_con <- .ComptoxREnv$ecotox_db
  old_burl <- Sys.getenv("eco_burl")
  on.exit({
    .ComptoxREnv$ecotox_db <- old_con
    Sys.setenv("eco_burl" = old_burl)
  }, add = TRUE)

  .ComptoxREnv$ecotox_db <- NULL
  suppressMessages(eco_server(1))
  con <- .eco_get_con()
  expect_true(DBI::dbIsValid(con))

  .eco_close_con()
  expect_null(.ComptoxREnv$ecotox_db)
  expect_false(DBI::dbIsValid(con))
})

test_that("eco_server() mode switch closes existing connection", {
  skip_if_not(file.exists(eco_path()), "ECOTOX database not installed")
  old_con <- .ComptoxREnv$ecotox_db
  old_burl <- Sys.getenv("eco_burl")
  on.exit({
    .eco_close_con()
    .ComptoxREnv$ecotox_db <- old_con
    Sys.setenv("eco_burl" = old_burl)
  }, add = TRUE)

  .ComptoxREnv$ecotox_db <- NULL
  suppressMessages(eco_server(1))
  con <- .eco_get_con()
  expect_true(DBI::dbIsValid(con))

  # Switch to mode 2 (Plumber) — should close the DuckDB connection
  suppressMessages(eco_server(2))
  expect_false(DBI::dbIsValid(con))
  expect_null(.ComptoxREnv$ecotox_db)
})
