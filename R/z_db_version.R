# Content-aware database publishing helpers ---------------------------------

.DB_CLOWDER_DATASET <- "https://clowder.edap-cluster.com/api/datasets/61147fefe4b0856fdc65639b/listAllFiles"

#' @keywords internal
.db_trim_scalar <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(NA_character_)
  }
  x <- as.character(x[[1]])
  if (is.na(x)) {
    return(NA_character_)
  }
  trimws(x)
}

#' @keywords internal
.db_is_missing_string <- function(x) {
  value <- .db_trim_scalar(x)
  is.na(value) || !nzchar(value)
}

#' @keywords internal
.db_parse_logical <- function(x) {
  if (is.logical(x)) {
    return(isTRUE(x[[1]]))
  }
  value <- tolower(.db_trim_scalar(x))
  !is.na(value) && value %in% c("1", "true", "yes", "y")
}

#' @keywords internal
.db_parse_number <- function(x, default = NA_real_) {
  value <- .db_trim_scalar(x)
  if (is.na(value) || !nzchar(value)) {
    return(default)
  }
  out <- suppressWarnings(as.numeric(value))
  if (is.na(out)) {
    return(default)
  }
  out
}

#' @keywords internal
.db_clowder_file_list <- function() {
  httr2::request(.DB_CLOWDER_DATASET) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(30) |>
    httr2::req_perform() |>
    httr2::resp_body_json()
}

#' @keywords internal
.db_list_value <- function(x, name, default = "") {
  value <- x[[name]]
  if (is.null(value) || length(value) == 0L || is.na(value[[1]])) {
    return(default)
  }
  as.character(value[[1]])
}

#' @keywords internal
.dsstox_upstream_version_from_fields <- function(date_created, file_id) {
  date_created <- .db_trim_scalar(date_created)
  file_id <- .db_trim_scalar(file_id)
  if (.db_is_missing_string(date_created) || .db_is_missing_string(file_id)) {
    cli::cli_abort("DSSTox upstream version requires both {.field date-created} and file id.")
  }
  paste(date_created, file_id, sep = "|")
}

#' @keywords internal
.dsstox_upstream_version_from_entry <- function(entry) {
  date_created <- entry[["date_created"]]
  if (is.null(date_created)) {
    date_created <- entry[["date-created"]]
  }
  .dsstox_upstream_version_from_fields(date_created, entry[["id"]])
}

#' @keywords internal
.dsstox_latest_upstream_entry <- function(file_list = NULL) {
  if (is.null(file_list)) {
    file_list <- .db_clowder_file_list()
  }
  if (!is.list(file_list) || length(file_list) == 0L) {
    cli::cli_abort("Unexpected Clowder response: no files found.")
  }

  entries <- purrr::map(file_list, function(x) {
    list(
      id = .db_list_value(x, "id"),
      filename = .db_list_value(x, "filename"),
      date_created = .db_list_value(x, "date-created"),
      content_type = .db_list_value(x, "contentType")
    )
  }) |>
    purrr::keep(function(x) {
      grepl("multi/files-zipped", x$content_type, fixed = TRUE) &&
        grepl("DSSTox_", x$filename, fixed = TRUE) &&
        grepl("[.]zip$", x$filename, ignore.case = TRUE) &&
        !grepl("SDF", x$filename, ignore.case = TRUE)
    }) |>
    purrr::map(tibble::as_tibble) |>
    dplyr::bind_rows()

  if (nrow(entries) == 0L) {
    cli::cli_abort("No DSSTox ZIP files found on Clowder.")
  }

  parsed <- entries |>
    dplyr::mutate(
      date_created_parsed = lubridate::parse_date_time(.data$date_created, orders = "a b d HMS Y")
    )

  if (all(is.na(parsed$date_created_parsed))) {
    cli::cli_abort(
      "Could not parse any DSSTox Clowder release dates (e.g. {.val {utils::head(entries$date_created, 3)}})."
    )
  }

  parsed |>
    dplyr::arrange(dplyr::desc(.data$date_created_parsed)) |>
    dplyr::slice_head(n = 1)
}

#' @keywords internal
.dsstox_latest_upstream_version <- function(file_list = NULL) {
  .dsstox_latest_upstream_entry(file_list) |>
    .dsstox_upstream_version_from_entry()
}

#' @keywords internal
.ecotox_ascii_releases <- function(ftp_url = "https://gaftp.epa.gov/ecotox/") {
  ftp_resp <- httr2::request(ftp_url) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(30) |>
    httr2::req_perform()

  ftp_links <- httr2::resp_body_string(ftp_resp) |>
    rvest::read_html() |>
    rvest::html_elements("a") |>
    rvest::html_attr("href")

  zip_files <- ftp_links[
    grepl("^ecotox_ascii_[0-9]{2}_[0-9]{2}_[0-9]{4}[.]zip$", ftp_links, ignore.case = TRUE)
  ]
  if (length(zip_files) == 0L) {
    cli::cli_abort("No zip files found on EPA ECOTOX FTP.")
  }

  tibble::tibble(file = zip_files) |>
    dplyr::mutate(
      release_date = stringr::str_remove_all(.data$file, "ecotox_ascii_"),
      release_date = stringr::str_remove_all(.data$release_date, "[.]zip"),
      release_date = lubridate::as_date(.data$release_date, format = "%m_%d_%Y")
    ) |>
    dplyr::arrange(dplyr::desc(.data$release_date))
}

#' @keywords internal
.ecotox_latest_upstream_version <- function(ftp_url = "https://gaftp.epa.gov/ecotox/") {
  releases <- .ecotox_ascii_releases(ftp_url = ftp_url)
  releases$file[[1]]
}

#' @keywords internal
.toxval_version_key <- function(version) {
  parts <- regmatches(version, regexec("^v([0-9]{2,3})_([0-9]+)$", version))[[1]]
  if (length(parts) != 3L) {
    return(c(major = -Inf, minor = -Inf))
  }
  c(major = as.integer(parts[[2]]), minor = as.integer(parts[[3]]))
}

#' @keywords internal
.toxval_latest_version <- function(versions) {
  versions <- unique(stats::na.omit(as.character(versions)))
  versions <- versions[nzchar(versions)]
  if (length(versions) == 0L) {
    cli::cli_abort("No ToxValDB version strings found in Clowder files.")
  }

  keys <- t(vapply(versions, .toxval_version_key, numeric(2)))
  versions[order(keys[, "major"], keys[, "minor"], decreasing = TRUE)][[1]]
}

#' @keywords internal
.toxval_latest_upstream_version <- function(file_list = NULL) {
  if (is.null(file_list)) {
    file_list <- .db_clowder_file_list()
  }
  if (!is.list(file_list) || length(file_list) == 0L) {
    cli::cli_abort("Unexpected Clowder response: no files found.")
  }

  filenames <- vapply(file_list, .db_list_value, character(1), name = "filename")
  toxval_files <- filenames[
    grepl("^toxval_all_res_toxval_v[0-9]{2,3}_[0-9]+.*[.]xlsx$", filenames, ignore.case = TRUE)
  ]
  versions <- stringr::str_extract(toxval_files, "v[0-9]{2,3}_[0-9]+")
  .toxval_latest_version(versions)
}

#' @keywords internal
.db_latest_upstream_version <- function(db_name) {
  db_name <- match.arg(db_name, c("dsstox", "ecotox", "toxval"))
  switch(
    db_name,
    dsstox = .dsstox_latest_upstream_version(),
    ecotox = .ecotox_latest_upstream_version(),
    toxval = .toxval_latest_upstream_version()
  )
}

#' @keywords internal
.db_rebuild_needed <- function(
  published_version,
  upstream_version,
  asset_age_days = NA_real_,
  force = FALSE,
  backstop_days = Inf
) {
  force <- .db_parse_logical(force)
  asset_age_days <- .db_parse_number(asset_age_days, default = NA_real_)
  backstop_days <- .db_parse_number(backstop_days, default = Inf)

  if (.db_is_missing_string(upstream_version)) {
    cli::cli_abort("{.arg upstream_version} must be a non-empty string.")
  }

  if (force) {
    return(list(needed = TRUE, reason = "force"))
  }

  if (.db_is_missing_string(published_version)) {
    return(list(needed = TRUE, reason = "missing_published_version"))
  }

  published_version <- .db_trim_scalar(published_version)
  upstream_version <- .db_trim_scalar(upstream_version)

  if (!identical(published_version, upstream_version)) {
    return(list(needed = TRUE, reason = "version_mismatch"))
  }

  if (is.finite(backstop_days) && is.na(asset_age_days)) {
    return(list(needed = TRUE, reason = "missing_asset_age"))
  }

  if (is.finite(backstop_days) && asset_age_days > backstop_days) {
    return(list(needed = TRUE, reason = "backstop_age"))
  }

  list(needed = FALSE, reason = "current")
}

#' @keywords internal
.db_emit_outputs <- function(outputs) {
  values <- paste0(names(outputs), "=", as.character(outputs))
  cat(paste0(values, collapse = "\n"), "\n", sep = "")

  github_output <- Sys.getenv("GITHUB_OUTPUT", unset = "")
  if (nzchar(github_output)) {
    cat(paste0(values, collapse = "\n"), "\n", file = github_output, append = TRUE, sep = "")
  }

  invisible(outputs)
}

#' @keywords internal
.db_gate_decision <- function(
  db_name = Sys.getenv("DB_NAME", unset = ""),
  published_version = Sys.getenv("PUBLISHED_VERSION", unset = NA_character_),
  asset_age_days = Sys.getenv("ASSET_AGE_DAYS", unset = NA_character_),
  force = Sys.getenv("FORCE", unset = "false"),
  backstop_days = Sys.getenv("BACKSTOP_DAYS", unset = "Inf")
) {
  db_name <- match.arg(.db_trim_scalar(db_name), c("dsstox", "ecotox", "toxval"))
  upstream_version <- .db_latest_upstream_version(db_name)
  decision <- .db_rebuild_needed(
    published_version = published_version,
    upstream_version = upstream_version,
    asset_age_days = asset_age_days,
    force = force,
    backstop_days = backstop_days
  )

  outputs <- c(
    needed = tolower(as.character(decision$needed)),
    reason = decision$reason,
    upstream_version = upstream_version,
    published_version = if (.db_is_missing_string(published_version)) "" else .db_trim_scalar(published_version),
    asset_age_days = if (is.na(.db_parse_number(asset_age_days))) "" else as.character(.db_parse_number(asset_age_days))
  )
  .db_emit_outputs(outputs)

  invisible(list(
    db_name = db_name,
    needed = decision$needed,
    reason = decision$reason,
    upstream_version = upstream_version,
    published_version = published_version,
    asset_age_days = .db_parse_number(asset_age_days)
  ))
}

#' @keywords internal
.db_write_version_sidecar <- function(db_path, version) {
  db_path <- .db_trim_scalar(db_path)
  version <- .db_trim_scalar(version)
  if (.db_is_missing_string(db_path) || .db_is_missing_string(version)) {
    cli::cli_abort("Database sidecar writing requires a database path and version.")
  }

  version_path <- sub("[.]duckdb$", ".version", db_path, ignore.case = TRUE)
  if (identical(version_path, db_path)) {
    version_path <- paste0(db_path, ".version")
  }
  writeLines(version, version_path, useBytes = TRUE)
  invisible(version_path)
}

#' @keywords internal
.db_metadata_table <- function(con) {
  if (!DBI::dbExistsTable(con, "_metadata")) {
    return(data.frame())
  }
  DBI::dbReadTable(con, "_metadata")
}

#' @keywords internal
.db_metadata_value <- function(metadata, key) {
  if (!all(c("key", "value") %in% names(metadata))) {
    return(NA_character_)
  }
  values <- metadata$value[metadata$key == key]
  value <- if (length(values) == 0L) NA_character_ else values[[1]]
  .db_trim_scalar(value)
}

#' @keywords internal
.db_local_recorded_version <- function(db_name, con = NULL, path = NULL) {
  db_name <- match.arg(db_name, c("dsstox", "ecotox", "toxval"))
  owns_connection <- is.null(con)
  if (owns_connection) {
    if (is.null(path) || !file.exists(path)) {
      return(NA_character_)
    }
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE)
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  }

  metadata <- tryCatch(.db_metadata_table(con), error = function(e) data.frame())
  if (nrow(metadata) == 0L) {
    return(NA_character_)
  }

  if (identical(db_name, "dsstox")) {
    release_date <- .db_metadata_value(metadata, "dsstox_release_date")
    clowder_id <- .db_metadata_value(metadata, "dsstox_clowder_id")
    if (.db_is_missing_string(release_date) || .db_is_missing_string(clowder_id)) {
      return(NA_character_)
    }
    return(.dsstox_upstream_version_from_fields(release_date, clowder_id))
  }

  if (identical(db_name, "ecotox")) {
    return(.db_metadata_value(metadata, "ecotox_release"))
  }

  if (all(c("version", "is_latest") %in% names(metadata))) {
    latest <- metadata[metadata$is_latest %in% TRUE, , drop = FALSE]
    if (nrow(latest) > 0L) {
      return(.db_trim_scalar(latest$version[[1]]))
    }
  }
  if ("version" %in% names(metadata) && nrow(metadata) > 0L) {
    return(.db_trim_scalar(metadata$version[[1]]))
  }

  NA_character_
}

#' @keywords internal
.db_file_age_days <- function(path) {
  if (!file.exists(path)) {
    return(NA_real_)
  }
  as.numeric(difftime(Sys.time(), file.info(path)$mtime, units = "days"))
}

#' @keywords internal
.db_diag_freshness <- function(db_name, path, latest_fun, install_call, rebuild_call) {
  db_name <- match.arg(db_name, c("dsstox", "ecotox", "toxval"))
  installed <- file.exists(path)
  local_version <- if (installed) {
    tryCatch(.db_local_recorded_version(db_name, path = path), error = function(e) NA_character_)
  } else {
    NA_character_
  }
  latest_version <- tryCatch(latest_fun(), error = function(e) {
    cli::cli_warn("Could not check latest upstream version: {conditionMessage(e)}")
    NA_character_
  })
  file_age_days <- .db_file_age_days(path)

  status <- dplyr::case_when(
    !installed ~ "missing",
    .db_is_missing_string(local_version) ~ "unknown",
    .db_is_missing_string(latest_version) ~ "unknown",
    identical(local_version, latest_version) ~ "current",
    TRUE ~ "stale"
  )
  guidance <- dplyr::case_when(
    status == "missing" ~ paste0("Install with ", install_call, "."),
    status == "stale" ~ paste0("Rebuild with ", rebuild_call, " or reinstall from db-latest."),
    status == "unknown" ~ "Inspect local metadata and upstream connectivity.",
    TRUE ~ "No action needed."
  )

  cli::cli_h1("{toupper(db_name)} Freshness Check")
  cli::cli_alert_info("Local recorded version: {.val {local_version}}")
  cli::cli_alert_info("Latest upstream version: {.val {latest_version}}")
  if (installed) {
    cli::cli_alert_info("DB file age: {round(file_age_days, 1)} day{?s}")
  } else {
    cli::cli_alert_warning("Database file not found at {.path {path}}")
  }
  if (identical(status, "current")) {
    cli::cli_alert_success("Database is current.")
  } else {
    cli::cli_alert_warning("Database status: {status}. {guidance}")
  }

  invisible(list(
    database = db_name,
    path = path,
    local_version = local_version,
    latest_upstream_version = latest_version,
    db_file_age_days = file_age_days,
    status = status,
    guidance = guidance
  ))
}

#' Check DSSTox database freshness
#'
#' Compares the installed DSSTox database metadata against the latest DSSTox
#' Clowder ZIP signal used by the rolling database build workflow.
#'
#' @param path Path to a DSSTox `.duckdb` file. Defaults to [dss_path()].
#' @return Invisibly, a named list with local version, upstream version, file
#'   age, status, and guidance.
#' @export
#' @family dsstox
dss_diag_freshness <- function(path = dss_path()) {
  .db_diag_freshness(
    db_name = "dsstox",
    path = path,
    latest_fun = .dsstox_latest_upstream_version,
    install_call = "dss_install(overwrite = TRUE)",
    rebuild_call = "dss_install(build = TRUE, overwrite = TRUE)"
  )
}

#' Check ECOTOX database freshness
#'
#' Compares the installed ECOTOX database metadata against the latest ECOTOX
#' ASCII release slug used by the rolling database build workflow.
#'
#' @param path Path to an ECOTOX `.duckdb` file. Defaults to [eco_path()].
#' @return Invisibly, a named list with local version, upstream version, file
#'   age, status, and guidance.
#' @export
#' @family ecotox
eco_diag_freshness <- function(path = eco_path()) {
  .db_diag_freshness(
    db_name = "ecotox",
    path = path,
    latest_fun = .ecotox_latest_upstream_version,
    install_call = "eco_install(overwrite = TRUE)",
    rebuild_call = "eco_install(build = TRUE, overwrite = TRUE)"
  )
}

#' Check ToxValDB database freshness
#'
#' Compares the installed ToxValDB metadata against the latest ToxValDB version
#' present on the public Clowder endpoint used by the source build.
#'
#' @param path Path to a ToxValDB `.duckdb` file. Defaults to [toxval_path()].
#' @return Invisibly, a named list with local version, upstream version, file
#'   age, status, and guidance.
#' @export
#' @family toxval
toxval_diag_freshness <- function(path = toxval_path()) {
  .db_diag_freshness(
    db_name = "toxval",
    path = path,
    latest_fun = .toxval_latest_upstream_version,
    install_call = "toxval_install(overwrite = TRUE)",
    rebuild_call = "toxval_install(build = TRUE, overwrite = TRUE)"
  )
}
