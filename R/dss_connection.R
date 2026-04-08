# DSSTox Local Database — Connection Management
# -----------------------------------------------

#' Get the path to the DSSTox database
#'
#' Resolves the location of the local DSSTox DuckDB database. Checks
#' `getOption("ComptoxR.dsstox_path")` first, then falls back to
#' `tools::R_user_dir("ComptoxR", "data")`.
#'
#' @return A character string with the full file path.
#' @keywords internal
dss_path <- function() {
  opt <- getOption("ComptoxR.dsstox_path")
  if (!is.null(opt) && nzchar(opt)) {
    return(opt)
  }
  file.path(tools::R_user_dir("ComptoxR", "data"), "dsstox.duckdb")
}

#' Get or create a DSSTox database connection
#'
#' Returns an existing valid connection or creates a new read-only connection
#' to the DSSTox DuckDB database. The connection is cached in the internal
#' `.ComptoxREnv` environment for the session.
#'
#' @param con An optional existing `DBI::DBIConnection`. If valid, returned
#'   as-is.
#' @return A `DBI::DBIConnection` to the DSSTox database.
#' @keywords internal
dss_get_con <- function(con = NULL) {
  # Use caller-supplied connection if valid

  if (!is.null(con) && inherits(con, "DBIConnection") && DBI::dbIsValid(con)) {
    return(con)
  }

  # Use cached connection if valid
  cached <- .ComptoxREnv$dsstox_db
  if (!is.null(cached) && inherits(cached, "DBIConnection") && DBI::dbIsValid(cached)) {
    return(cached)
  }

  # Create new connection
  path <- dss_path()
  if (!file.exists(path)) {
    cli::cli_abort(c(
      "DSSTox database not found at {.path {path}}.",
      "i" = "Run {.run dss_install(source = 'path/to/dsstox.duckdb')} to install it.",
      "i" = "Or run {.run dss_install()} to build from source."
    ))
  }

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE)
  .ComptoxREnv$dsstox_db <- con
  con
}

#' Connect to the DSSTox local database
#'
#' Explicitly opens a read-only connection to the local DSSTox DuckDB database.
#' If `path` is provided it is saved as the default for the session via
#' `options(ComptoxR.dsstox_path = path)`.
#'
#' @param path Optional path to a DSSTox `.duckdb` file. If `NULL`, uses the
#'   default from `dss_path()`.
#' @return Invisibly, the `DBI::DBIConnection`.
#' @export
#' @family dsstox
dss_connect <- function(path = NULL) {
  if (!is.null(path)) {
    options(ComptoxR.dsstox_path = path)
  }
  con <- dss_get_con()
  cli::cli_alert_success("Connected to DSSTox database at {.path {dss_path()}}")
  invisible(con)
}

#' Disconnect from the DSSTox local database
#'
#' Closes the cached DSSTox connection and removes it from the internal
#' environment.
#'
#' @return Invisibly, `NULL`.
#' @export
#' @family dsstox
dss_disconnect <- function() {
  con <- .ComptoxREnv$dsstox_db
  if (!is.null(con) && inherits(con, "DBIConnection") && DBI::dbIsValid(con)) {
    DBI::dbDisconnect(con, shutdown = TRUE)
    cli::cli_alert_success("DSSTox database disconnected.")
  }
  .ComptoxREnv$dsstox_db <- NULL
  invisible(NULL)
}

#' Install the DSSTox local database
#'
#' Copies a pre-built DSSTox DuckDB file to the package data directory, or
#' runs the ETL build pipeline from source if no file is provided.
#'
#' @param source Path to an existing `dsstox.duckdb` file. If `NULL`, runs
#'   the build script at `data-raw/dsstox.R`.
#' @param overwrite Logical; overwrite an existing database? Default `FALSE`.
#' @return Invisibly, the destination path.
#' @export
#' @family dsstox
dss_install <- function(source = NULL, overwrite = FALSE) {
  dest <- dss_path()
  dest_dir <- dirname(dest)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (file.exists(dest) && !overwrite) {
    cli::cli_abort(c(
      "DSSTox database already exists at {.path {dest}}.",
      "i" = "Use {.code dss_install(overwrite = TRUE)} to replace it."
    ))
  }

  if (!is.null(source)) {
    if (!file.exists(source)) {
      cli::cli_abort("Source file not found: {.path {source}}")
    }
    file.copy(source, dest, overwrite = TRUE)
    cli::cli_alert_success("Installed DSSTox database to {.path {dest}}")
  } else {
    build_script <- system.file("data-raw", "dsstox.R", package = "ComptoxR")
    if (!nzchar(build_script)) {
      # Fallback for development (not yet installed)
      build_script <- file.path(
        system.file(package = "ComptoxR"),
        "..", "data-raw", "dsstox.R"
      )
    }
    if (!file.exists(build_script)) {
      cli::cli_abort(c(
        "Build script not found.",
        "i" = "Provide a {.arg source} path to a pre-built database instead."
      ))
    }
    cli::cli_alert_info("Running ETL build pipeline...")
    source(build_script, local = new.env(parent = globalenv()))
    cli::cli_alert_success("DSSTox database built at {.path {dest}}")
  }

  invisible(dest)
}
