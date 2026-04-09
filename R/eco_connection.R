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
      "i" = "Run {.run eco_install(source = 'path/to/ecotox.duckdb')} to install from a file.",
      "i" = "Or run {.run eco_install()} to build from source."
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
#' Installs the ECOTOX DuckDB database. By default, downloads a pre-built
#' database from the latest GitHub Release. Falls back to building from source
#' if the release asset is not available.
#'
#' @param source Path to an existing `ecotox.duckdb` file. If provided, the
#'   file is copied directly (skipping download and build).
#' @param build Logical; if `TRUE`, skip the download attempt and build from
#'   source immediately. Default `FALSE`.
#' @param tag GitHub release tag to download from (e.g. `"v2.1.0"`). Default
#'   `"latest"`.
#' @param overwrite Logical; overwrite an existing database? Default `FALSE`.
#' @return Invisibly, the destination path.
#' @export
#' @family ecotox
eco_install <- function(source = NULL, build = FALSE, tag = "latest",
                        overwrite = FALSE) {
  dest <- eco_path()
  dest_dir <- dirname(dest)

  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (file.exists(dest) && !overwrite) {
    cli::cli_abort(c(
      "ECOTOX database already exists at {.path {dest}}.",
      "i" = "Use {.code eco_install(overwrite = TRUE)} to replace it."
    ))
  }

  # 1. Local source file (explicit path)
  if (!is.null(source)) {
    if (!file.exists(source)) {
      cli::cli_abort("Source file not found: {.path {source}}")
    }
    file.copy(source, dest, overwrite = TRUE)
    cli::cli_alert_success("Installed ECOTOX database to {.path {dest}}")
    return(invisible(dest))
  }

  # 2. Build from source (explicit opt-in)
  if (isTRUE(build)) {
    .eco_build_from_source(dest)
    return(invisible(dest))
  }

  # 3. Default: try GitHub Release download, fall back to build
  tryCatch(
    .db_download_release("ecotox", dest, tag = tag),
    error = function(e) {
      cli::cli_warn(c(
        "Could not download ECOTOX database from GitHub Release.",
        "i" = conditionMessage(e),
        "i" = "Falling back to build-from-source."
      ))
      .eco_build_from_source(dest)
    }
  )

  invisible(dest)
}

#' Build ECOTOX from source ETL script
#' @param dest Destination path for the database.
#' @keywords internal
#' @noRd
.eco_build_from_source <- function(dest) {
  build_script <- system.file("ecotox", "ecotox_build.R", package = "ComptoxR")
  if (!nzchar(build_script) || !file.exists(build_script)) {
    cli::cli_abort(c(
      "Build script not found. Build-from-source requires a development install.",
      "i" = "Provide a {.arg source} path to a pre-built database instead."
    ))
  }
  cli::cli_alert_info("Running ECOTOX ETL build pipeline...")
  source(build_script, local = new.env(parent = globalenv()))

  if (!file.exists(dest)) {
    cli::cli_abort(c(
      "Build script completed but database was not created at {.path {dest}}.",
      "i" = "The ETL script may have failed silently or written to a different location.",
      "i" = "Provide a {.arg source} path to a pre-built database instead."
    ))
  }
  cli::cli_alert_success("ECOTOX database built at {.path {dest}}")
}
