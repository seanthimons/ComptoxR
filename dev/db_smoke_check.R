# Smoke-check a built rolling database asset before release upload.

.smoke_arg <- function(name, default = "") {
  prefix <- paste0("--", name, "=")
  args <- commandArgs(trailingOnly = TRUE)
  match <- args[startsWith(args, prefix)]
  if (length(match) > 0L) {
    return(sub(prefix, "", match[[1]], fixed = TRUE))
  }

  env_name <- toupper(name)
  value <- Sys.getenv(env_name, unset = "")
  if (nzchar(value)) {
    return(value)
  }

  default
}

.smoke_load_version_helpers <- function() {
  helper_path <- file.path(getwd(), "R", "z_db_version.R")
  if (file.exists(helper_path)) {
    sys.source(helper_path, envir = globalenv())
    return(invisible(TRUE))
  }

  if ("ComptoxR" %in% loadedNamespaces()) {
    ns <- asNamespace("ComptoxR")
    for (fn in c(".db_is_missing_string", ".db_local_recorded_version")) {
      assign(fn, get(fn, envir = ns), envir = globalenv())
    }
    return(invisible(TRUE))
  }

  cli::cli_abort("Shared database version helper layer not available.")
}

.smoke_db_path <- function(db_name) {
  env_path <- Sys.getenv("DB_PATH", unset = "")
  if (nzchar(env_path)) {
    return(env_path)
  }
  file.path(tools::R_user_dir("ComptoxR", "data"), paste0(db_name, ".duckdb"))
}

.smoke_version_path <- function(db_path) {
  env_path <- Sys.getenv("VERSION_PATH", unset = "")
  if (nzchar(env_path)) {
    return(env_path)
  }
  sub("[.]duckdb$", ".version", db_path, ignore.case = TRUE)
}

.smoke_row_floor <- function(db_name) {
  override <- Sys.getenv("MIN_ROWS", unset = "")
  if (nzchar(override)) {
    return(as.integer(override))
  }

  switch(
    db_name,
    dsstox = 100000L,
    ecotox = 100000L,
    toxval = 100000L
  )
}

.smoke_core_table <- function(db_name) {
  switch(
    db_name,
    dsstox = "dsstox",
    ecotox = "results",
    toxval = "toxval"
  )
}

.smoke_check <- function() {
  .smoke_load_version_helpers()

  db_name <- match.arg(.smoke_arg("db_name", Sys.getenv("DB_NAME", unset = "")), c("dsstox", "ecotox", "toxval"))
  db_path <- .smoke_db_path(db_name)
  version_path <- .smoke_version_path(db_path)
  core_table <- .smoke_core_table(db_name)
  row_floor <- .smoke_row_floor(db_name)

  if (!file.exists(db_path)) {
    cli::cli_abort("Database file not found at {.path {db_path}}.")
  }
  if (!file.exists(version_path)) {
    cli::cli_abort("Version sidecar not found at {.path {version_path}}.")
  }

  sidecar_version <- trimws(readLines(version_path, n = 1L, warn = FALSE))
  if (.db_is_missing_string(sidecar_version)) {
    cli::cli_abort("Version sidecar is empty at {.path {version_path}}.")
  }

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  if (!DBI::dbExistsTable(con, core_table)) {
    cli::cli_abort("Core table {.table {core_table}} not found in {.path {db_path}}.")
  }
  if (!DBI::dbExistsTable(con, "_metadata")) {
    cli::cli_abort("Metadata table {.table _metadata} not found in {.path {db_path}}.")
  }

  row_count <- DBI::dbGetQuery(con, sprintf('SELECT count(*) AS n FROM "%s"', core_table))$n[[1]]
  if (is.na(row_count) || row_count < row_floor) {
    cli::cli_abort(c(
      "Core table row-count smoke check failed.",
      "x" = "{.table {core_table}} has {row_count} row(s); expected at least {row_floor}."
    ))
  }

  local_version <- .db_local_recorded_version(db_name, con = con)
  if (.db_is_missing_string(local_version)) {
    cli::cli_abort("Local database metadata does not record a version for {.val {db_name}}.")
  }
  if (!identical(local_version, sidecar_version)) {
    cli::cli_abort(c(
      "Version sidecar does not match database metadata.",
      "x" = "Metadata: {.val {local_version}}.",
      "x" = "Sidecar: {.val {sidecar_version}}."
    ))
  }

  cli::cli_alert_success(
    "{db_name} smoke check passed: {format(row_count, big.mark = ',')} rows in {core_table}, version {sidecar_version}."
  )
  invisible(TRUE)
}

.smoke_check()
