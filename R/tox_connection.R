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
      "i" = "Run {.run tox_install()} to download from GitHub Releases.",
      "i" = "Or run {.run tox_install(source = 'path/to/toxval.duckdb')} to install from a local file."
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
#' Installs the ToxValDB DuckDB database. By default, downloads a pre-built
#' database from the latest GitHub Release. Falls back to building from source
#' if the release asset is not available.
#'
#' @param source Path to an existing `toxval.duckdb` file. If provided, the
#'   file is copied directly (skipping download and build).
#' @param build Logical; if `TRUE`, skip the download attempt and build from
#'   source immediately. Default `FALSE`.
#' @param tag GitHub release tag to download from (e.g. `"v2.1.0"`). Default
#'   `"latest"`.
#' @param overwrite Logical; overwrite an existing database? Default `FALSE`.
#' @return Invisibly, the destination path.
#' @export
#' @family toxval
tox_install <- function(source = NULL, build = FALSE, tag = "latest",
                        overwrite = FALSE) {
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

  # 1. Local source file (explicit path)
  if (!is.null(source)) {
    if (!file.exists(source)) {
      cli::cli_abort("Source file not found: {.path {source}}")
    }
    file.copy(source, dest, overwrite = TRUE)
    cli::cli_alert_success("Installed ToxValDB database to {.path {dest}}")
    return(invisible(dest))
  }

  # 2. Build from source (explicit opt-in)
  if (isTRUE(build)) {
    .tox_build_from_source(dest)
    return(invisible(dest))
  }

  # 3. Default: try GitHub Release download, fall back to build
  tryCatch(
    .db_download_release("toxval", dest, tag = tag),
    error = function(e) {
      cli::cli_warn(c(
        "Could not download ToxValDB from GitHub Release.",
        "i" = conditionMessage(e),
        "i" = "Falling back to build-from-source."
      ))
      .tox_build_from_source(dest)
    }
  )

  invisible(dest)
}

#' Build ToxValDB from source ETL script
#' @param dest Destination path for the database.
#' @keywords internal
#' @noRd
.tox_build_from_source <- function(dest) {
  build_script <- system.file("toxval", "toxval_build.R", package = "ComptoxR")
  if (!nzchar(build_script) || !file.exists(build_script)) {
    cli::cli_abort(c(
      "Build script not found. Build-from-source requires a development install.",
      "i" = "Provide a {.arg source} path to a pre-built database instead."
    ))
  }
  cli::cli_alert_info("Running ToxValDB ETL build pipeline...")
  source(build_script, local = new.env(parent = globalenv()))

  if (!file.exists(dest)) {
    cli::cli_abort(c(
      "Build script completed but database was not created at {.path {dest}}.",
      "i" = "The ETL script may have failed silently or written to a different location.",
      "i" = "Provide a {.arg source} path to a pre-built database instead."
    ))
  }
  cli::cli_alert_success("ToxValDB database built at {.path {dest}}")
}
