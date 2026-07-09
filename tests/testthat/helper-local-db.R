# Shared skip + fixture helpers for local-resource tests.
#
# These back the future DSS/ECOTOX/ToxVal/EPI/Plumber test issues (#222-226).
# They keep those tests CRAN-safe: anything that needs a local database, an
# external executable, or an "integration only" resource skips instead of
# reaching out. See README-local-db-fixtures.md for the policy behind them.
#
# Note: helper-api.R already ships `skip_if_no_local_db(db)` for the two named
# option-backed DuckDBs (ecotox, toxval). The `_at()` variant below is for the
# general case where a test knows the concrete path (e.g. a DSS db, a temp
# fixture, or a path computed via `dss_path()`).

#' Skip when a local database file at `path` is absent
#'
#' The general, path-based counterpart to `skip_if_no_local_db(db)`. Use it when
#' the test already has the file path (`dss_path()`, `eco_path()`, a temp
#' fixture, etc.). In the CRAN-safe lane `setup.R` points the option paths at a
#' missing directory, so option-derived paths skip automatically.
skip_if_no_local_db_at <- function(path, label = "local database") {
  if (!length(path) || is.na(path) || !nzchar(path) || !file.exists(path)) {
    shown <- if (length(path) && !is.na(path) && nzchar(path)) path else "<none>"
    testthat::skip(sprintf("%s not installed (%s)", label, shown))
  }
  invisible(path)
}

#' Skip when an external executable is not on PATH
#'
#' For tests that shell out (e.g. a bundled Plumber/EPI Suite binary). `cmd` is
#' resolved with `Sys.which()`; an empty result means it is not installed.
skip_if_no_executable <- function(cmd) {
  found <- unname(Sys.which(cmd))
  if (!nzchar(found)) {
    testthat::skip(sprintf("executable '%s' not found on PATH", cmd))
  }
  invisible(found)
}

#' Skip integration-only tests unless explicitly opted in
#'
#' Integration tests (live Plumber service, real local DB round-trips) run only
#' when `COMPTOXR_RUN_INTEGRATION` is truthy AND the CRAN-safe lane is inactive.
skip_if_integration_only <- function(
  reason = "integration-only test (set COMPTOXR_RUN_INTEGRATION=true to run)"
) {
  if (comptoxr_cran_safe_tests()) {
    testthat::skip(reason)
  }
  opt_in <- tolower(trimws(Sys.getenv("COMPTOXR_RUN_INTEGRATION", unset = "")))
  if (!opt_in %in% c("true", "1", "yes")) {
    testthat::skip(reason)
  }
  invisible(TRUE)
}

#' Create a temporary DuckDB fixture and register its cleanup
#'
#' Trivial fixture builder for tests that genuinely need a real (tiny) DuckDB.
#' Returns the file path; the connection is opened, `tables` (a named list of
#' data frames) are written, then the connection is closed. The file is removed
#' via `withr::defer()` on the caller's `envir` (so pass `environment()` or let
#' it default to the test's local frame).
#'
#' Skips when duckdb/DBI/withr are unavailable rather than erroring, keeping the
#' helper safe to call from any lane.
local_temp_duckdb <- function(tables = list(), envir = parent.frame()) {
  testthat::skip_if_not_installed("duckdb")
  testthat::skip_if_not_installed("DBI")
  testthat::skip_if_not_installed("withr")

  path <- withr::local_tempfile(fileext = ".duckdb", .local_envir = envir)
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE), envir = envir)

  for (nm in names(tables)) {
    DBI::dbWriteTable(con, nm, tables[[nm]])
  }

  path
}
