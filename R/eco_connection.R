# ECOTOX Local Database — Connection Management
# -----------------------------------------------

#' Get the path to the ECOTOX database
#'
#' Resolves the location of the local ECOTOX DuckDB database. Checks
#' `getOption("ComptoxR.ecotox_path")` first, then falls back to
#' `tools::R_user_dir("ComptoxR", "data")`.
#'
#' @return A character string with the full file path.
#' @keywords internal
eco_path <- function() {
  opt <- getOption("ComptoxR.ecotox_path")
  if (!is.null(opt) && nzchar(opt)) {
    return(opt)
  }
  file.path(tools::R_user_dir("ComptoxR", "data"), "ecotox.duckdb")
}

#' Get or create an ECOTOX database connection
#'
#' Returns an existing valid connection or creates a new read-only connection
#' to the ECOTOX DuckDB database. The connection is cached in the internal
#' `.ComptoxREnv` environment for the session.
#'
#' @param con An optional existing `DBI::DBIConnection`. If valid, returned
#'   as-is.
#' @return A `DBI::DBIConnection` to the ECOTOX database.
#' @keywords internal
.eco_get_con <- function(con = NULL) {
  # Use caller-supplied connection if valid
  if (!is.null(con) && inherits(con, "DBIConnection") && DBI::dbIsValid(con)) {
    return(con)
  }

  # Use cached connection if valid
  cached <- .ComptoxREnv$ecotox_db
  if (!is.null(cached) && inherits(cached, "DBIConnection") && DBI::dbIsValid(cached)) {
    return(cached)
  }

  # Resolve path: if eco_burl ends in .duckdb use that, else use eco_path()
  eco_burl <- Sys.getenv("eco_burl")
  if (nzchar(eco_burl) && grepl("\\.duckdb$", eco_burl)) {
    path <- eco_burl
  } else {
    path <- eco_path()
  }

  if (!file.exists(path)) {
    cli::cli_abort(c(
      "ECOTOX database not found at {.path {path}}.",
      "i" = "Run {.run eco_install(source = 'path/to/ecotox.duckdb')} to install it."
    ))
  }

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE)
  .ComptoxREnv$ecotox_db <- con
  con
}

#' Close cached ECOTOX database connection
#'
#' Closes the cached ECOTOX connection and removes it from the internal
#' environment. Safe to call when no connection exists.
#'
#' @return Invisibly, `NULL`.
#' @keywords internal
.eco_close_con <- function() {
  con <- .ComptoxREnv$ecotox_db
  if (!is.null(con) && inherits(con, "DBIConnection") && DBI::dbIsValid(con)) {
    DBI::dbDisconnect(con, shutdown = TRUE)
  }
  .ComptoxREnv$ecotox_db <- NULL
  invisible(NULL)
}

#' Install the ECOTOX local database
#'
#' Copies a pre-built ECOTOX DuckDB file to the package data directory.
#' Automated build from source is planned for a future release.
#'
#' @param source Path to an existing `ecotox.duckdb` file. Required in this
#'   release.
#' @param overwrite Logical; overwrite an existing database? Default `FALSE`.
#' @return Invisibly, the destination path.
#' @export
#' @family ecotox
eco_install <- function(source = NULL, overwrite = FALSE) {
  dest <- eco_path()
  dest_dir <- dirname(dest)

  if (is.null(source)) {
    cli::cli_abort(c(
      "A {.arg source} path to a pre-built ECOTOX database is required.",
      "i" = "Automated build from source is coming in a future release."
    ))
  }

  if (!file.exists(source)) {
    cli::cli_abort("Source file not found: {.path {source}}")
  }

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (file.exists(dest) && !overwrite) {
    cli::cli_abort(c(
      "ECOTOX database already exists at {.path {dest}}.",
      "i" = "Use {.code eco_install(overwrite = TRUE)} to replace it."
    ))
  }

  file.copy(source, dest, overwrite = TRUE)
  cli::cli_alert_success("Installed ECOTOX database to {.path {dest}}")
  invisible(dest)
}
