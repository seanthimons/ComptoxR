# ToxValDB ETL Build Pipeline
# -------------------------------------------------------------------
# Downloads ToxValDB per-source Excel files from the EPA Clowder API,
# stacks them, and writes a DuckDB database.
#
# Usage:
#   source(system.file("toxval", "toxval_build.R", package = "ComptoxR"))
#   .build_toxval_db()  # or call via toxval_install()

# Clowder dataset URL for ToxValDB v9 per-source files
.TOXVAL_CLOWDER_DATASET <- "https://clowder.edap-cluster.com/api/datasets/61147fefe4b0856fdc65639b/listAllFiles"

# Minimum expected row count for ToxValDB v9.x (sanity check)
.TOXVAL_MIN_ROWS <- 100000L

# Staleness threshold in days (rebuild if older than this)
.TOXVAL_STALENESS_DAYS <- 180

.build_toxval_db <- function(output_path = NULL, force = FALSE) {
  # 1. Dependency check
  rlang::check_installed(
    c("readxl", "janitor", "httr2"),
    reason = "to build the ToxValDB database from source"
  )

  # 2. Resolve output path
  if (is.null(output_path)) {
    output_path <- file.path(tools::R_user_dir("ComptoxR", "data"), "toxval.duckdb")
  }
  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # 3. Staleness check — skip if DB exists and is fresh
  if (!isTRUE(force) && file.exists(output_path)) {
    age_days <- as.numeric(
      difftime(Sys.time(), file.info(output_path)$mtime, units = "days")
    )
    if (age_days <= .TOXVAL_STALENESS_DAYS) {
      cli::cli_alert_success(
        "ToxValDB is up-to-date ({round(age_days)} days old). Skipping rebuild."
      )
      return(invisible(output_path))
    }
    cli::cli_alert_warning(
      "ToxValDB is {round(age_days)} days old. Rebuilding."
    )
  }

  # 4. Build in-memory to prevent partial writes on crash
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # 5. Create metadata table
  DBI::dbExecute(con, "
    CREATE TABLE IF NOT EXISTS _metadata (
      version VARCHAR,
      version_label VARCHAR,
      row_count INTEGER,
      loaded_at TIMESTAMP,
      is_latest BOOLEAN
    )
  ")

  # 6. Clowder API discovery (hardened)
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
        "i" = "Or use {.code toxval_install(source = 'path/to/toxval.duckdb')} with a pre-built file."
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


  # Filter for latest-version toxval per-source Excel files.
  # Dataset contains multiple versions (v92..v97) and QC-fail files —
  # keep only toxval_all_res_toxval_v9*_*.xlsx (the per-source data files).
  toxval_files <- purrr::keep(file_list, function(f) {
    fname <- f$filename %||% ""
    grepl("^toxval_all_res_toxval_v9.*\\.xlsx$", fname, ignore.case = TRUE)
  })

  # Keep only the latest version present
  if (length(toxval_files) > 0) {
    all_versions <- purrr::map_chr(toxval_files, ~ {
      stringr::str_extract(.x$filename, "v\\d{2,3}_\\d+") %||% ""
    })
    latest_ver <- sort(unique(all_versions), decreasing = TRUE)[1]
    toxval_files <- purrr::keep(toxval_files, function(f) {
      grepl(latest_ver, f$filename, fixed = TRUE)
    })
    cli::cli_alert_info("Using latest version: {latest_ver}")
  }

  if (length(toxval_files) == 0) {
    cli::cli_abort("No ToxValDB v9 Excel files found in Clowder dataset.")
  }

  # 7. Robust version extraction
  first_name <- toxval_files[[1]]$filename
  version_raw <- stringr::str_extract(first_name, "v\\d{2,3}_\\d+")

  if (is.na(version_raw)) {
    cli::cli_warn(
      "Could not extract version from filename: {.file {first_name}}. Using date-based fallback."
    )
    version_raw <- paste0("v_unknown_", format(Sys.Date(), "%Y%m%d"))
  }

  # Flexible label: "v97_0" -> "9.7.0", "v100_1" -> "10.0.1"
  version_label <- tryCatch({
    parts <- regmatches(version_raw, regexec("v(\\d+)_(\\d+)", version_raw))[[1]]
    if (length(parts) == 3) {
      major_raw <- as.integer(parts[2])
      minor <- as.integer(parts[3])
      sprintf("%d.%d.%d", major_raw %/% 10, major_raw %% 10, minor)
    } else {
      version_raw
    }
  }, error = function(e) version_raw)

  cli::cli_alert_info(
    "Found {length(toxval_files)} source file{?s} for ToxValDB {version_label}."
  )

  # 8. Download Excel files to isolated temp directory
  tmp_dir <- file.path(tempdir(), "toxval_build")
  dir.create(tmp_dir, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

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
        httr2::request(dl_url) |>
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

  # 9. Stack: read all as text, clean names, bind
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

  # 10. Row count sanity check
  if (nrow(stacked) < .TOXVAL_MIN_ROWS) {
    cli::cli_abort(c(
      "Row count sanity check failed: {nrow(stacked)} rows (expected >= {.TOXVAL_MIN_ROWS}).",
      "i" = "The Clowder data may be incomplete or the API response has changed.",
      "i" = "Use {.code toxval_install(source = 'path/to/toxval.duckdb')} with a pre-built file."
    ))
  }

  # 11. Type casting (R-side before DuckDB write)
  numeric_cols <- c("toxval_numeric", "toxval_numeric_original",
                    "study_duration_value", "study_duration_value_original",
                    "mw", "year", "original_year")

  for (col in intersect(numeric_cols, names(stacked))) {
    stacked[[col]] <- suppressWarnings(as.numeric(stacked[[col]]))
  }

  # 12. Write to in-memory DuckDB
  cli::cli_alert_info("Writing {nrow(stacked)} rows to in-memory DuckDB...")
  DBI::dbWriteTable(con, "toxval", stacked, overwrite = TRUE)

  # 13. Update metadata
  DBI::dbExecute(con, "UPDATE _metadata SET is_latest = FALSE")
  DBI::dbExecute(con,
    "INSERT INTO _metadata (version, version_label, row_count, loaded_at, is_latest) VALUES (?, ?, ?, ?, TRUE)",
    params = list(version_raw, version_label, nrow(stacked), Sys.time())
  )

  # 14. Persist atomically to disk
  cli::cli_alert_info("Persisting to {.path {output_path}}...")

  # Remove existing file first (ATTACH won't overwrite)
  if (file.exists(output_path)) {
    file.remove(output_path)
  }

  # Windows path fix for DuckDB ATTACH
  safe_path <- gsub("\\\\", "/", output_path)
  DBI::dbExecute(con, sprintf(
    "ATTACH '%s' AS persist", safe_path
  ))
  DBI::dbExecute(con, "COPY FROM DATABASE memory TO persist")
  DBI::dbExecute(con, "DETACH persist")

  cli::cli_alert_success(
    "ToxValDB {version_label} built: {nrow(stacked)} rows, {ncol(stacked)} columns."
  )

  invisible(output_path)
}
.build_toxval_db()
