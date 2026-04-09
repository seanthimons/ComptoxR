# ToxValDB ETL Build Pipeline
# -------------------------------------------------------------------
# Downloads ToxValDB per-source Excel files from the EPA Clowder API,
# stacks them, and writes a DuckDB database.
#
# Usage:
#   source(system.file("toxval", "toxval_build.R", package = "ComptoxR"))
#   .build_toxval_db()  # or call via tox_install()

# Clowder dataset URL for ToxValDB v9 per-source files
.TOXVAL_CLOWDER_DATASET <- "https://clowder.edap-cluster.com/api/datasets/6572f1d2e4b0bfe1afb58fec/files"

.build_toxval_db <- function(output_path = NULL) {
  # 1. Dependency check
  rlang::check_installed(
    c("readxl", "janitor", "httr2"),
    reason = "to build the ToxValDB database from source"
  )

  # 2. Resolve output path
  if (is.null(output_path)) {
    output_path <- ComptoxR::tox_path()
  }
  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # 3. DuckDB connect/create
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = output_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # 4. Create metadata table
 DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS _metadata (
      version VARCHAR,
      version_label VARCHAR,
      row_count INTEGER,
      loaded_at TIMESTAMP,
      is_latest BOOLEAN
    )
  ")

  # 5. Clowder API discovery (hardened)
  cli::cli_alert_info("Querying Clowder API for ToxValDB files...")

  file_list <- tryCatch(
    {
      resp <- httr2::request(.TOXVAL_CLOWDER_DATASET) |>
        httr2::req_retry(max_tries = 3, backoff = ~ 2) |>
        httr2::req_timeout(30) |>
        httr2::req_perform()
      httr2::resp_body_json(resp)
    },
    error = function(e) {
      cli::cli_abort(c(
        "Failed to query Clowder API for ToxValDB files.",
        "x" = conditionMessage(e),
        "i" = "The EPA Clowder server may be unavailable. Try again later.",
        "i" = "Or use {.code tox_install(source = 'path/to/toxval.duckdb')} with a pre-built file."
      ))
    }
  )

  # Validate response structure
  if (!is.list(file_list) || length(file_list) == 0) {
    cli::cli_abort(c(
      "Unexpected Clowder API response: no files found.",
      "i" = "The dataset structure may have changed."
    ))
  }

  # Filter for toxval_v9 Excel files
  toxval_files <- purrr::keep(file_list, function(f) {
    fname <- f$filename %||% ""
    grepl("^toxval_v9.*\\.xlsx$", fname, ignore.case = TRUE)
  })

  if (length(toxval_files) == 0) {
    cli::cli_abort("No ToxValDB v9 Excel files found in Clowder dataset.")
  }

  # Extract version string from first filename
  first_name <- toxval_files[[1]]$filename
  version_raw <- stringr::str_extract(first_name, "v\\d+_\\d+")
  if (is.na(version_raw)) version_raw <- "v97_0"

  # Version label: "v97_0" -> "9.7.0"
  version_label <- gsub("v(\\d)(\\d)_(\\d)", "\\1.\\2.\\3", version_raw)

  # 6. Check if already loaded
  existing <- DBI::dbGetQuery(con,
    "SELECT version FROM _metadata WHERE version = ?",
    params = list(version_raw)
  )
  if (nrow(existing) > 0) {
    cli::cli_alert_info("ToxValDB {version_label} already loaded. Skipping.")
    return(invisible(output_path))
  }

  cli::cli_alert_info(
    "Found {length(toxval_files)} source file{?s} for ToxValDB {version_label}."
  )

  # 7. Download Excel files to tempdir
  tmp_dir <- tempdir()
  downloaded_files <- character(0)

  cli::cli_progress_bar(
    "Downloading ToxValDB files",
    total = length(toxval_files)
  )

  for (f in toxval_files) {
    fname <- f$filename
    fid <- f$id
    dest_file <- file.path(tmp_dir, fname)

    dl_ok <- tryCatch(
      {
        dl_url <- paste0(
          "https://clowder.edap-cluster.com/api/files/", fid, "/blob"
        )
        resp <- httr2::request(dl_url) |>
          httr2::req_retry(max_tries = 3, backoff = ~ 2) |>
          httr2::req_timeout(120) |>
          httr2::req_perform(path = dest_file)
        TRUE
      },
      error = function(e) {
        cli::cli_alert_warning("Failed to download {fname}: {conditionMessage(e)}")
        FALSE
      }
    )

    if (dl_ok) {
      # Validate the file is readable Excel
      readable <- tryCatch(
        {
          readxl::read_excel(dest_file, n_max = 1)
          TRUE
        },
        error = function(e) {
          cli::cli_alert_warning("Skipping corrupt file: {fname}")
          FALSE
        }
      )
      if (readable) {
        downloaded_files <- c(downloaded_files, dest_file)
      }
    }

    cli::cli_progress_update()
  }

  cli::cli_progress_done()

  if (length(downloaded_files) == 0) {
    cli::cli_abort("No valid Excel files were downloaded.")
  }

  # 8. Stack: read all as text, clean names, bind
  cli::cli_alert_info("Reading and stacking {length(downloaded_files)} files...")

  all_dfs <- purrr::map(downloaded_files, function(path) {
    tryCatch(
      {
        readxl::read_excel(path, col_types = "text") |>
          janitor::clean_names()
      },
      error = function(e) {
        cli::cli_alert_warning("Error reading {basename(path)}: {conditionMessage(e)}")
        NULL
      }
    )
  })

  all_dfs <- purrr::compact(all_dfs)
  stacked <- purrr::list_rbind(all_dfs)

  cli::cli_alert_info("Stacked {nrow(stacked)} rows across {ncol(stacked)} columns.")

  # 9. Type casting (R-side before DuckDB write)
  numeric_cols <- c("toxval_numeric", "toxval_numeric_original",
                    "study_duration_value", "study_duration_value_original",
                    "mw", "year", "original_year")

  for (col in intersect(numeric_cols, names(stacked))) {
    stacked[[col]] <- suppressWarnings(as.numeric(stacked[[col]]))
  }

  # 10. Write to DuckDB
  cli::cli_alert_info("Writing to DuckDB at {.path {output_path}}...")
  DBI::dbWriteTable(con, "toxval", stacked, overwrite = TRUE)

  # 11. Update metadata
  DBI::dbExecute(con, "UPDATE _metadata SET is_latest = FALSE")
  DBI::dbExecute(con,
    "INSERT INTO _metadata (version, version_label, row_count, loaded_at, is_latest) VALUES (?, ?, ?, ?, TRUE)",
    params = list(version_raw, version_label, nrow(stacked), Sys.time())
  )

  cli::cli_alert_success(
    "ToxValDB {version_label} loaded: {nrow(stacked)} rows, {ncol(stacked)} columns."
  )

  # 12. Cleanup temp files
  file.remove(downloaded_files)

  invisible(output_path)
}
