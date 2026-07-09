# Self-tests for the shared local-resource skip/fixture helpers
# (helper-local-db.R). These verify the guards actually skip; they do not touch
# any real database, executable, or network.

test_that("skip_if_no_executable skips for a nonexistent binary", {
  expect_condition(
    skip_if_no_executable("definitely-not-a-real-binary-xyz"),
    class = "skip"
  )
})

test_that("skip_if_no_executable returns the path for a present binary", {
  # Rscript is guaranteed present in any R test session.
  rscript <- unname(Sys.which("Rscript"))
  skip_if(!nzchar(rscript), "Rscript not on PATH")
  expect_identical(skip_if_no_executable("Rscript"), rscript)
})

test_that("skip_if_no_local_db_at skips for a missing / empty path", {
  missing <- file.path(tempdir(), "comptoxr-no-such-db.duckdb")
  expect_condition(skip_if_no_local_db_at(missing), class = "skip")
  expect_condition(skip_if_no_local_db_at(""), class = "skip")
  expect_condition(skip_if_no_local_db_at(character(0)), class = "skip")
  expect_condition(skip_if_no_local_db_at(NA_character_), class = "skip")
})

test_that("skip_if_no_local_db_at returns the path when the file exists", {
  f <- withr::local_tempfile(fileext = ".duckdb")
  writeLines("stub", f)
  expect_identical(skip_if_no_local_db_at(f), f)
})

test_that("skip_if_integration_only skips unless opted in and out of CRAN-safe", {
  # Force the CRAN-safe lane on: must skip regardless of opt-in.
  withr::local_envvar(
    COMPTOXR_CRAN_SAFE_TESTS = "true",
    COMPTOXR_RUN_INTEGRATION = "true"
  )
  expect_condition(skip_if_integration_only(), class = "skip")

  # Not CRAN-safe but not opted in: must still skip.
  withr::local_envvar(
    COMPTOXR_CRAN_SAFE_TESTS = "false",
    NOT_CRAN = "true",
    COMPTOXR_RUN_INTEGRATION = ""
  )
  expect_condition(skip_if_integration_only(), class = "skip")
})

test_that("local_temp_duckdb builds a real fixture and cleans up", {
  skip_if_not_installed("duckdb")
  skip_if_not_installed("DBI")
  skip_if_not_installed("withr")

  path <- local_temp_duckdb(list(mtcars = mtcars[1:3, 1:2]))
  expect_true(file.exists(path))

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  expect_true("mtcars" %in% DBI::dbListTables(con))
  expect_equal(DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM mtcars")$n, 3)
})
