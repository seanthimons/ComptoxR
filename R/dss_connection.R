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
#' Installs the DSSTox DuckDB database. By default, downloads a pre-built
#' database from the latest GitHub Release. Falls back to building from source
#' if the release asset is not available.
#'
#' @param source Path to an existing `dsstox.duckdb` file. If provided, the
#'   file is copied directly (skipping download and build).
#' @param build Logical; if `TRUE`, skip the download attempt and build from
#'   source immediately. Default `FALSE`.
#' @param tag GitHub release tag to download from (e.g. `"v2.1.0"`). Default
#'   `"latest"`.
#' @param overwrite Logical; overwrite an existing database? Default `FALSE`.
#' @return Invisibly, the destination path.
#' @export
#' @family dsstox
dss_install <- function(source = NULL, build = FALSE, tag = "latest",
                        overwrite = FALSE) {
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

  # 1. Local source file (explicit path)
  if (!is.null(source)) {
    if (!file.exists(source)) {
      cli::cli_abort("Source file not found: {.path {source}}")
    }
    file.copy(source, dest, overwrite = TRUE)
    cli::cli_alert_success("Installed DSSTox database to {.path {dest}}")
    return(invisible(dest))
  }

  # 2. Build from source (explicit opt-in)
  if (isTRUE(build)) {
    .dss_build_from_source(dest)
    return(invisible(dest))
  }

  # 3. Default: try GitHub Release download, fall back to build
  tryCatch(
    .db_download_release("dsstox", dest, tag = tag),
    error = function(e) {
      cli::cli_warn(c(
        "Could not download DSSTox database from GitHub Release.",
        "i" = conditionMessage(e),
        "i" = "Falling back to build-from-source."
      ))
      .dss_build_from_source(dest)
    }
  )

  if (!file.exists(dest)) cli::cli_abort("Installation failed: database not found at {.path {dest}}")
  invisible(dest)
}

#' Build DSSTox from source ETL script
#' @param dest Destination path for the database.
#' @keywords internal
#' @noRd
.dss_build_from_source <- function(dest) {
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
  cli::cli_alert_info("Running DSSTox ETL build pipeline...")
  source(build_script, local = new.env(parent = globalenv()))

  if (!file.exists(dest)) {
    cli::cli_abort(c(
      "Build script completed but database was not created at {.path {dest}}.",
      "i" = "The ETL script may have failed silently or written to a different location.",
      "i" = "Provide a {.arg source} path to a pre-built database instead."
    ))
  }
  cli::cli_alert_success("DSSTox database built at {.path {dest}}")
}
