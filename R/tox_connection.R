# ToxValDB Local Database — Connection Management
# -----------------------------------------------

#' Get the path to the ToxValDB database
#'
#' Resolves the location of the local ToxValDB DuckDB database. Checks
#' `getOption("ComptoxR.toxval_path")` first, then falls back to
#' `tools::R_user_dir("ComptoxR", "data")`.
#'
#' @return A character string with the full file path.
#' @keywords internal
tox_path <- function() {
  opt <- getOption("ComptoxR.toxval_path")
  if (!is.null(opt) && nzchar(opt)) {
    return(opt)
  }
  file.path(tools::R_user_dir("ComptoxR", "data"), "toxval.duckdb")
}

#' Get or create a ToxValDB database connection
#'
#' Returns an existing valid connection or creates a new read-only connection
#' to the ToxValDB DuckDB database. The connection is cached in the internal
#' `.ComptoxREnv` environment for the session.
#'
#' @param con An optional existing `DBI::DBIConnection`. If valid, returned
#'   as-is.
#' @return A `DBI::DBIConnection` to the ToxValDB database.
#' @keywords internal
.tox_get_con <- function(con = NULL) {
  # Use caller-supplied connection if valid
  if (!is.null(con) && inherits(con, "DBIConnection") && DBI::dbIsValid(con)) {
    return(con)
  }

  # Use cached connection if valid
  cached <- .ComptoxREnv$toxval_db
  if (!is.null(cached) && inherits(cached, "DBIConnection") && DBI::dbIsValid(cached)) {
    return(cached)
  }

  # Resolve path: if tox_burl ends in .duckdb use that, else use tox_path()
  tox_burl <- Sys.getenv("tox_burl")
  if (nzchar(tox_burl) && grepl("\\.duckdb$", tox_burl)) {
    path <- tox_burl
  } else {
    path <- tox_path()
  }

  if (!file.exists(path)) {
    cli::cli_abort(c(
      "ToxValDB database not found at {.path {path}}.",
      "i" = "Run {.run tox_install(source = 'path/to/toxval.duckdb')} to install from a file.",
      "i" = "Or run {.run tox_install()} to build from source."
    ))
  }

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE)
  .ComptoxREnv$toxval_db <- con
  con
}

#' Close cached ToxValDB database connection
#'
#' Closes the cached ToxValDB connection and removes it from the internal
#' environment. Safe to call when no connection exists.
#'
#' @return Invisibly, `NULL`.
#' @keywords internal
.tox_close_con <- function() {
  con <- .ComptoxREnv$toxval_db
  if (!is.null(con) && inherits(con, "DBIConnection") && DBI::dbIsValid(con)) {
    DBI::dbDisconnect(con, shutdown = TRUE)
  }
  .ComptoxREnv$toxval_db <- NULL
  invisible(NULL)
}

#' Install the ToxValDB local database
#'
#' Copies a pre-built ToxValDB DuckDB file to the package data directory, or
#' runs the ETL build pipeline from source if no file is provided.
#'
#' @param source Path to an existing `toxval.duckdb` file. If `NULL`, runs
#'   the build script at `inst/toxval/toxval_build.R`.
#' @param overwrite Logical; overwrite an existing database? Default `FALSE`.
#' @return Invisibly, the destination path.
#' @export
#' @family toxval
tox_install <- function(source = NULL, overwrite = FALSE) {
  dest <- tox_path()
  dest_dir <- dirname(dest)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (file.exists(dest) && !overwrite) {
    cli::cli_abort(c(
      "ToxValDB database already exists at {.path {dest}}.",
      "i" = "Use {.code tox_install(overwrite = TRUE)} to replace it."
    ))
  }

  if (!is.null(source)) {
    if (!file.exists(source)) {
      cli::cli_abort("Source file not found: {.path {source}}")
    }
    file.copy(source, dest, overwrite = TRUE)
    cli::cli_alert_success("Installed ToxValDB database to {.path {dest}}")
  } else {
    build_script <- system.file("toxval", "toxval_build.R", package = "ComptoxR")
    if (!nzchar(build_script) || !file.exists(build_script)) {
      cli::cli_abort(c(
        "Build script not found. Build-from-source requires a development install.",
        "i" = "Provide a {.arg source} path to a pre-built database instead."
      ))
    }
    cli::cli_alert_info("Running ToxValDB ETL build pipeline...")
    source(build_script, local = new.env(parent = globalenv()))
    cli::cli_alert_success("ToxValDB database built at {.path {dest}}")
  }

  invisible(dest)
}
