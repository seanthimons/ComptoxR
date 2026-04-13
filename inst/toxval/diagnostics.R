# ToxValDB Diagnostic Scripts
# -------------------------------------------------------------------
# Lightweight checks to inform design decisions and verify data quality.
# Run interactively or via: source(system.file("toxval", "diagnostics.R", package = "ComptoxR"))
#
# Requires: a built ToxValDB (run toxval_install() first)

# --- Schema & Column Coverage ------------------------------------------------

#' Check ToxValDB column coverage and sparsity
#'
#' Reports per-column non-null counts, coverage percentages, and identifies
#' empty columns. Useful for deciding which columns belong in the default
#' return set vs. "all" mode.
toxval_diag_columns <- function(con = NULL) {
  if (is.null(con)) {
    con <- DBI::dbConnect(
      duckdb::duckdb(),
      dbdir = ComptoxR::toxval_path()(),
      read_only = TRUE
    )
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  }

  total <- DBI::dbGetQuery(con, "SELECT count(*) AS n FROM toxval")$n
  cols <- DBI::dbListFields(con, "toxval")

  cli::cli_h1("ToxValDB Column Coverage ({total} rows)")

  results <- purrr::map_dfr(cols, function(col) {
    nn <- DBI::dbGetQuery(con, sprintf(
      'SELECT count("%s") AS n FROM toxval WHERE "%s" IS NOT NULL', col, col
    ))$n
    tibble::tibble(
      column = col,
      non_null = nn,
      pct = round(100 * nn / total, 1)
    )
  })

  results <- results[order(-results$pct), ]

  # Tier classification
  results$tier <- dplyr::case_when(
    results$pct == 0 ~ "empty",
    results$pct < 10 ~ "sparse (<10%)",
    results$pct < 50 ~ "moderate (10-50%)",
    TRUE ~ "universal (>50%)"
  )

  cli::cli_h2("Empty columns (0% coverage)")
  empty <- results[results$pct == 0, ]
  if (nrow(empty) > 0) {
    cli::cli_li(empty$column)
  } else {
    cli::cli_alert_success("None")
  }

  cli::cli_h2("Tier Summary")
  tier_summary <- table(results$tier)
  for (nm in names(tier_summary)) {
    cli::cli_alert_info("{nm}: {tier_summary[[nm]]} columns")
  }

  invisible(results)
}


# --- Schema Drift Detection --------------------------------------------------

#' Compare ToxValDB columns against expected default set
#'
#' Detects columns added or removed between ToxVal versions. Useful for
#' catching schema drift that would break .tox_default_cols().
toxval_diag_schema_drift <- function(con = NULL) {
  if (is.null(con)) {
    con <- DBI::dbConnect(
      duckdb::duckdb(),
      dbdir = ComptoxR::toxval_path()(),
      read_only = TRUE
    )
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  }

  actual <- DBI::dbListFields(con, "toxval")

  # Load default cols from package
  default_cols <- ComptoxR:::.tox_default_cols()

  missing_from_db <- setdiff(default_cols, actual)
  extra_in_db <- setdiff(actual, default_cols)

  cli::cli_h1("Schema Drift Report")

  if (length(missing_from_db) > 0) {
    cli::cli_alert_danger("Columns in default set but MISSING from database:")
    cli::cli_li(missing_from_db)
  } else {
    cli::cli_alert_success("All default columns present in database.")
  }

  if (length(extra_in_db) > 0) {
    cli::cli_alert_info("Columns in database but NOT in default set ({length(extra_in_db)}):")
    cli::cli_li(extra_in_db)
  }

  invisible(list(
    missing_from_db = missing_from_db,
    extra_in_db = extra_in_db
  ))
}


# --- Data Quality Checks ----------------------------------------------------

#' Run basic data quality checks on ToxValDB
#'
#' Checks row counts, source distribution, QC status breakdown, and
#' verifies key identifier columns are populated.
toxval_diag_quality <- function(con = NULL) {
  if (is.null(con)) {
    con <- DBI::dbConnect(
      duckdb::duckdb(),
      dbdir = ComptoxR::toxval_path()(),
      read_only = TRUE
    )
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  }

  cli::cli_h1("ToxValDB Data Quality Report")

  # Metadata
  meta <- tryCatch(
    DBI::dbGetQuery(con,
      "SELECT version_label, row_count, loaded_at FROM _metadata WHERE is_latest = TRUE"
    ),
    error = function(e) data.frame()
  )
  if (nrow(meta) > 0) {
    cli::cli_alert_info("Version: {meta$version_label} | Rows: {meta$row_count} | Built: {meta$loaded_at}")
  }

  # Total rows
  total <- DBI::dbGetQuery(con, "SELECT count(*) AS n FROM toxval")$n
  cli::cli_alert_info("Actual row count: {total}")

  # Source distribution
  sources <- DBI::dbGetQuery(con,
    "SELECT source, count(*) AS n FROM toxval GROUP BY source ORDER BY n DESC LIMIT 10"
  )
  cli::cli_h2("Top 10 Sources")
  for (i in seq_len(nrow(sources))) {
    cli::cli_alert("{sources$source[i]}: {sources$n[i]} rows")
  }

  n_sources <- DBI::dbGetQuery(con, "SELECT count(DISTINCT source) AS n FROM toxval")$n
  cli::cli_alert_info("Total distinct sources: {n_sources}")

  # QC status breakdown
  qc <- DBI::dbGetQuery(con,
    "SELECT qc_status, count(*) AS n FROM toxval GROUP BY qc_status ORDER BY n DESC"
  )
  cli::cli_h2("QC Status Distribution")
  for (i in seq_len(nrow(qc))) {
    label <- if (is.na(qc$qc_status[i])) "<NA>" else qc$qc_status[i]
    cli::cli_alert("{label}: {qc$n[i]} rows ({round(100 * qc$n[i] / total, 1)}%)")
  }

  # Key identifier coverage
  cli::cli_h2("Key Identifier Coverage")
  for (col in c("dtxsid", "casrn", "name", "human_eco")) {
    nn <- DBI::dbGetQuery(con, sprintf(
      'SELECT count(*) AS n FROM toxval WHERE "%s" IS NOT NULL', col
    ))$n
    pct <- round(100 * nn / total, 1)
    if (pct > 95) {
      cli::cli_alert_success("{col}: {pct}%")
    } else if (pct > 50) {
      cli::cli_alert_info("{col}: {pct}%")
    } else {
      cli::cli_alert_warning("{col}: {pct}%")
    }
  }

  # human_eco distribution (design decision: is this a useful filter?)
  he <- DBI::dbGetQuery(con,
    "SELECT human_eco, count(*) AS n FROM toxval GROUP BY human_eco ORDER BY n DESC"
  )
  cli::cli_h2("human_eco Distribution (filter param validation)")
  for (i in seq_len(nrow(he))) {
    label <- if (is.na(he$human_eco[i])) "<NA>" else he$human_eco[i]
    cli::cli_alert("{label}: {he$n[i]} ({round(100 * he$n[i] / total, 1)}%)")
  }

  invisible(list(total = total, sources = sources, qc = qc, human_eco = he))
}


# --- Clowder API Probe ------------------------------------------------------

#' Probe the Clowder API without downloading files
#'
#' Tests API connectivity, reports available versions and file counts.
#' Useful for debugging build failures or checking for new ToxVal releases.
toxval_diag_clowder <- function() {
  url <- "https://clowder.edap-cluster.com/api/datasets/6572f1d2e4b0bfe1afb58fec/files"

  cli::cli_h1("Clowder API Probe")

  resp <- tryCatch(
    {
      r <- httr2::request(url) |>
        httr2::req_timeout(15) |>
        httr2::req_perform()
      cli::cli_alert_success("API reachable (HTTP {httr2::resp_status(r)})")
      r
    },
    error = function(e) {
      cli::cli_alert_danger("API unreachable: {conditionMessage(e)}")
      return(invisible(NULL))
    }
  )

  if (is.null(resp)) return(invisible(NULL))

  files <- httr2::resp_body_json(resp)
  cli::cli_alert_info("Total items in dataset: {length(files)}")

  # Extract filenames
  fnames <- vapply(files, function(f) f$filename %||% "<unnamed>", character(1))

  # Identify ToxVal Excel files
  tv_files <- fnames[grepl("^toxval_v9.*\\.xlsx$", fnames, ignore.case = TRUE)]

  # Version breakdown
  versions <- unique(stringr::str_extract(tv_files, "v\\d{2,3}_\\d+"))
  versions <- versions[!is.na(versions)]

  cli::cli_h2("ToxVal v9 Excel Files")
  cli::cli_alert_info("{length(tv_files)} files across {length(versions)} version(s)")
  for (v in versions) {
    n <- sum(grepl(v, tv_files, fixed = TRUE))
    cli::cli_alert("  {v}: {n} files")
  }

  # Non-ToxVal items
  other <- fnames[!grepl("^toxval_v9.*\\.xlsx$", fnames, ignore.case = TRUE)]
  if (length(other) > 0) {
    cli::cli_h2("Other Files ({length(other)})")
    cli::cli_li(utils::head(other, 10))
    if (length(other) > 10) cli::cli_alert_info("... and {length(other) - 10} more")
  }

  invisible(list(
    total_files = length(files),
    toxval_files = length(tv_files),
    versions = versions,
    filenames = fnames
  ))
}


# --- Version Comparison ------------------------------------------------------

#' Compare installed ToxValDB version against Clowder latest
#'
#' Reports whether the local database is current or behind the EPA release.
toxval_diag_freshness <- function() {
  cli::cli_h1("ToxValDB Freshness Check")

  # Local version
  path <- ComptoxR::toxval_path()()
  if (!file.exists(path)) {
    cli::cli_alert_danger("ToxValDB not installed at {.path {path}}")
    return(invisible(NULL))
  }

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  local_meta <- tryCatch(
    DBI::dbGetQuery(con, "SELECT version, version_label, loaded_at FROM _metadata WHERE is_latest = TRUE"),
    error = function(e) data.frame()
  )

  if (nrow(local_meta) > 0) {
    age_days <- as.numeric(difftime(Sys.time(), local_meta$loaded_at, units = "days"))
    cli::cli_alert_info("Local: {local_meta$version_label} (built {round(age_days)} days ago)")
  } else {
    cli::cli_alert_warning("No metadata found in local database")
  }

  # File age
  file_age <- as.numeric(difftime(Sys.time(), file.info(path)$mtime, units = "days"))
  cli::cli_alert_info("File age: {round(file_age)} days (threshold: 180)")

  if (file_age > 180) {
    cli::cli_alert_warning("Database is stale. Run {.code toxval_install(build = TRUE, overwrite = TRUE)} to rebuild.")
  } else {
    cli::cli_alert_success("Database is fresh.")
  }

  # Remote check
  cli::cli_alert_info("Checking Clowder for latest version...")
  remote <- tryCatch(
    {
      resp <- httr2::request("https://clowder.edap-cluster.com/api/datasets/6572f1d2e4b0bfe1afb58fec/files") |>
        httr2::req_timeout(10) |>
        httr2::req_perform()
      files <- httr2::resp_body_json(resp)
      fnames <- vapply(files, function(f) f$filename %||% "", character(1))
      tv <- fnames[grepl("^toxval_v9.*\\.xlsx$", fnames, ignore.case = TRUE)]
      versions <- unique(stringr::str_extract(tv, "v\\d{2,3}_\\d+"))
      versions[!is.na(versions)]
    },
    error = function(e) {
      cli::cli_alert_warning("Could not reach Clowder: {conditionMessage(e)}")
      character(0)
    }
  )

  if (length(remote) > 0) {
    cli::cli_alert_info("Remote version(s): {paste(remote, collapse = ', ')}")
    if (nrow(local_meta) > 0 && local_meta$version %in% remote) {
      cli::cli_alert_success("Local version matches remote.")
    } else if (nrow(local_meta) > 0) {
      cli::cli_alert_warning("Version mismatch: local={local_meta$version}, remote={paste(remote, collapse=',')}")
    }
  }

  invisible(list(local = local_meta, remote = remote, file_age_days = file_age))
}
