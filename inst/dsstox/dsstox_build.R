# DSSTox Database Build Pipeline
# ================================
# Downloads DSSTox dump from EPA Clowder, converts to long-form DuckDB.
# Output: tools::R_user_dir("ComptoxR", "data") / dsstox.duckdb
#
# Usage:
#   Rscript data-raw/dsstox.R
#   DSSTOX_ZIP=/path/to/DSSTox.zip Rscript data-raw/dsstox.R  (skip Clowder)
#   — or —
#   dss_install()  (from within ComptoxR)

.dsstox_load_db_version_helpers <- function() {
  env <- parent.frame()
  helper_path <- file.path(getwd(), "R", "z_db_version.R")
  if (file.exists(helper_path)) {
    sys.source(helper_path, envir = env)
    return(invisible(TRUE))
  }

  if ("ComptoxR" %in% loadedNamespaces()) {
    ns <- asNamespace("ComptoxR")
    for (fn in c(
      ".dsstox_latest_upstream_entry",
      ".dsstox_upstream_version_from_entry",
      ".db_is_missing_string",
      ".db_local_recorded_version",
      ".db_write_version_sidecar"
    )) {
      assign(fn, get(fn, envir = ns), envir = env)
    }
    return(invisible(TRUE))
  }

  cli::cli_abort("Shared database version helper layer not available.")
}

.build_dsstox_db <- function() {
  # -- Configuration ----------------------------------------------------------

  .dsstox_load_db_version_helpers()

  output_dir <- tools::R_user_dir("ComptoxR", "data")
  output_path <- file.path(output_dir, "dsstox.duckdb")

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # A local zip is an explicit rebuild request, so it bypasses the staleness check
  local_zip <- Sys.getenv("DSSTOX_ZIP")
  if (nzchar(local_zip) && !file.exists(local_zip)) {
    cli::cli_abort("{.envvar DSSTOX_ZIP} file not found: {.path {local_zip}}")
  }

  # -- Staleness check --------------------------------------------------------

  if (file.exists(output_path) && !nzchar(local_zip)) {
    file_age_days <- as.numeric(
      difftime(Sys.time(), file.info(output_path)$mtime, units = "days")
    )
    if (file_age_days <= 180) {
      cli::cli_alert_success(
        "DSSTox database is up-to-date ({round(file_age_days)} days old). Skipping rebuild."
      )
      existing_version <- tryCatch(
        .db_local_recorded_version("dsstox", path = output_path),
        error = function(e) NA_character_
      )
      if (!.db_is_missing_string(existing_version)) {
        .db_write_version_sidecar(output_path, existing_version)
      }
      return(invisible(output_path))
    } else {
      cli::cli_alert_warning(
        "DSSTox database is {round(file_age_days)} days old. Rebuilding."
      )
    }
  }

  # -- Download from Clowder -------------------------------------------------

  if (nzchar(local_zip)) {
    cli::cli_alert_info("Using local DSSTox zip {.path {local_zip}}.")
    # ponytail: version keys on file mtime; the next Clowder release reads as new and rebuilds once
    dss_entry <- list(id = "local", date_created = format(file.mtime(local_zip), "%Y-%m-%d"))
  } else {
    cli::cli_alert_info("Fetching file list from Clowder...")
    dss_entry <- .dsstox_latest_upstream_entry()
  }
  dss_version <- .dsstox_upstream_version_from_entry(dss_entry)

  # -- Download & extract -----------------------------------------------------

  raw_dir <- tempfile("dsstox_raw_")
  if (!dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)) {
    cli::cli_abort(c(
      "Failed to create temporary work directory.",
      "x" = "Path: {.path {raw_dir}}",
      "i" = "Check Windows temp directory permissions or antivirus settings.",
      "i" = "You can also provide a pre-built file: {.code dss_install(source = 'path/to/dsstox.duckdb')}"
    ))
  }
  on.exit(unlink(raw_dir, recursive = TRUE), add = TRUE)

  zip_path <- file.path(raw_dir, "dsstox.zip")
  old_timeout <- getOption("timeout")
  options(timeout = 3600)
  on.exit(options(timeout = old_timeout), add = TRUE)
  if (nzchar(local_zip)) {
    file.copy(local_zip, zip_path)
  } else {
    download.file(
      url = paste0("https://clowder.edap-cluster.com/api/files/", dss_entry$id, "/blob"),
      destfile = zip_path,
      mode = "wb",
      quiet = FALSE
    )
  }

  utils::unzip(zip_path, exdir = raw_dir)
  file.remove(zip_path)

  # -- Resolve data files -----------------------------------------------------

  all_data_files <- list.files(
    raw_dir,
    pattern = "\\.(csv|xlsx?|tsv)$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )

  if (length(all_data_files) == 0) {
    cli::cli_abort("No data files found in extracted archive.")
  }

  # Prefer split files over monolithic dump to avoid double-counting
  file_basenames <- tools::file_path_sans_ext(basename(all_data_files))
  is_split <- grepl("\\d+$", file_basenames)

  if (any(is_split) && !all(is_split)) {
    cli::cli_alert_info(
      "Found both aggregate and split files. Using {sum(is_split)} split files."
    )
    data_files <- all_data_files[is_split]
  } else {
    data_files <- all_data_files
  }

  # Partition by format
  file_exts <- tolower(tools::file_ext(data_files))
  csv_files <- data_files[file_exts %in% c("csv", "tsv")]
  xlsx_files <- data_files[file_exts %in% c("xlsx", "xls")]

  # Convert XLSX/XLS to temp CSVs
  if (length(xlsx_files) > 0) {
    cli::cli_alert_info("Converting {length(xlsx_files)} Excel file(s) to CSV.")
    converted_csvs <- vapply(
      xlsx_files,
      function(f) {
        tmp <- tempfile(fileext = ".csv")
        df <- readxl::read_excel(f, col_types = "text", na = c("-", ""))
        readr::write_csv(df, tmp)
        tmp
      },
      character(1),
      USE.NAMES = FALSE
    )
    csv_files <- c(csv_files, converted_csvs)
  }

  if (length(csv_files) == 0) {
    cli::cli_abort("No ingestible data files found after format resolution.")
  }

  cli::cli_alert_info("Ingesting {length(csv_files)} file(s) via DuckDB.")

  # -- DuckDB pipeline --------------------------------------------------------

  # Remove existing DB if present (we're rebuilding)
  if (file.exists(output_path)) {
    file.remove(output_path)
  }

  dsstox_db <- DBI::dbConnect(
    duckdb::duckdb(),
    dbdir = output_path,
    read_only = FALSE
  )
  on.exit(DBI::dbDisconnect(dsstox_db, shutdown = TRUE), add = TRUE)

  # Read all CSVs into staging table
  csv_list_sql <- paste0("'", gsub("\\\\", "/", csv_files), "'", collapse = ", ")

  DBI::dbExecute(
    dsstox_db,
    paste0(
      "CREATE TABLE dsstox_raw AS
   SELECT * FROM read_csv(
     [",
      csv_list_sql,
      "],
     all_varchar = true,
     union_by_name = true,
     parallel = false,
     null_padding = true,
     nullstr = ['-', '']
   )"
    )
  )

  # Exports differ in header style ("preferred name" vs PREFERRED_NAME); normalize to the latter
  for (col in DBI::dbListFields(dsstox_db, "dsstox_raw")) {
    norm <- toupper(gsub("[^A-Za-z0-9]+", "_", trimws(col)))
    if (!identical(norm, col)) {
      DBI::dbExecute(dsstox_db, sprintf('ALTER TABLE dsstox_raw RENAME COLUMN "%s" TO "%s"', col, norm))
    }
  }
  raw_cols <- DBI::dbListFields(dsstox_db, "dsstox_raw")
  if (!"DTXSID" %in% raw_cols) {
    cli::cli_abort(c("DSSTox export has no DTXSID column.", "i" = "Columns: {raw_cols}"))
  }
  # Columns absent from a given export (e.g. newer dumps drop INCHIKEY/IDENTIFIER) become NULL
  for (col in c("PREFERRED_NAME", "CASRN", "MOLECULAR_FORMULA", "INCHIKEY", "IUPAC_NAME",
                "SMILES", "IDENTIFIER", "DTXCID", "INCHI")) {
    DBI::dbExecute(dsstox_db, sprintf("ALTER TABLE dsstox_raw ADD COLUMN IF NOT EXISTS %s VARCHAR", col))
  }

  raw_count <- DBI::dbGetQuery(dsstox_db, "SELECT count(*) AS n FROM dsstox_raw")$n
  cli::cli_alert_success("Loaded {format(raw_count, big.mark = ',')} raw rows.")

  expected_min <- length(csv_files) * 10000L
  if (raw_count < expected_min) {
    cli::cli_abort(c(
      "Row count sanity check failed.",
      "x" = "Loaded {format(raw_count, big.mark=',')} rows from {length(csv_files)} files.",
      "i" = "Expected at least {format(expected_min, big.mark=',')}."
    ))
  }

  # Transform to long form
  DBI::dbExecute(
    dsstox_db,
    "CREATE TABLE dsstox AS
   WITH
   base AS (
     SELECT DTXSID, PREFERRED_NAME, CASRN, INCHIKEY, IUPAC_NAME,
            SMILES, MOLECULAR_FORMULA, IDENTIFIER, DTXCID, INCHI
     FROM dsstox_raw
   ),
   exploded AS (
     SELECT
       DTXSID, PREFERRED_NAME, CASRN, INCHIKEY, IUPAC_NAME,
       SMILES, MOLECULAR_FORMULA, DTXCID, INCHI,
       TRIM(id.ident) AS IDENTIFIER,
       TRIM(UPPER(id.ident)) AS ident_upper
     FROM base,
     LATERAL unnest(string_split(COALESCE(IDENTIFIER, ''), '|')) AS id(ident)
     WHERE TRIM(COALESCE(id.ident, '')) != ''
     UNION ALL
     SELECT
       DTXSID, PREFERRED_NAME, CASRN, INCHIKEY, IUPAC_NAME,
       SMILES, MOLECULAR_FORMULA, DTXCID, INCHI,
       NULL AS IDENTIFIER, NULL AS ident_upper
     FROM base
     WHERE IDENTIFIER IS NULL
   ),
   filtered AS (
     SELECT * FROM exploded
     WHERE IDENTIFIER IS NULL
        OR (CASRN != IDENTIFIER AND CASRN != ident_upper)
   ),
   unpivoted AS (
     SELECT DISTINCT DTXSID, parent_col, values
     FROM filtered
     UNPIVOT (
       values FOR parent_col IN (
         PREFERRED_NAME, CASRN, MOLECULAR_FORMULA, INCHIKEY,
         IUPAC_NAME, SMILES, ident_upper, IDENTIFIER, DTXCID, INCHI
       )
     )
     WHERE values IS NOT NULL
   )
   SELECT
     DTXSID, parent_col, values,
     CASE parent_col
       WHEN 'PREFERRED_NAME'    THEN 1
       WHEN 'CASRN'             THEN 2
       WHEN 'MOLECULAR_FORMULA' THEN 3
       WHEN 'INCHIKEY'          THEN 4
       WHEN 'IUPAC_NAME'        THEN 5
       WHEN 'SMILES'            THEN 6
       WHEN 'ident_upper'       THEN 7
       WHEN 'IDENTIFIER'        THEN 8
       WHEN 'DTXCID'            THEN 9
       WHEN 'INCHI'             THEN 10
     END AS sort_order
   FROM unpivoted
   ORDER BY DTXSID, sort_order"
  )

  final_count <- DBI::dbGetQuery(dsstox_db, "SELECT count(*) AS n FROM dsstox")$n
  cli::cli_alert_success("Built dsstox table: {format(final_count, big.mark = ',')} rows.")

  DBI::dbExecute(dsstox_db, "DROP TABLE dsstox_raw")

  metadata <- data.frame(
    key = c("build_date", "dsstox_release_date", "dsstox_clowder_id", "builder", "builder_version"),
    value = c(
      as.character(Sys.Date()),
      dss_entry$date_created[[1]],
      dss_entry$id[[1]],
      "ComptoxR",
      as.character(utils::packageVersion("ComptoxR"))
    ),
    stringsAsFactors = FALSE
  )
  DBI::dbWriteTable(dsstox_db, "_metadata", metadata, overwrite = TRUE)
  .db_write_version_sidecar(output_path, dss_version)

  # Clean up temp XLSX conversions
  if (length(xlsx_files) > 0) {
    file.remove(converted_csvs)
  }

  cli::cli_alert_success("DSSTox database saved to {.path {output_path}}")

  invisible(output_path)
}

.build_dsstox_db()
