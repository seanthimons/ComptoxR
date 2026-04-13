# ToxValDB Local Database — Core Query Functions
# -----------------------------------------------

# Internal helpers --------------------------------------------------------

#' Determine ToxValDB routing mode
#'
#' Checks `toxval_burl()` env var and returns the access mode.
#' @return `"duckdb"` or `"plumber"`.
#' @keywords internal
.tox_route <- function() {
  burl <- Sys.getenv("toxval_burl()")

  if (nzchar(burl) && grepl("\\.duckdb$", burl)) {
    return("duckdb")
  }

  if (nzchar(burl) && grepl("^https?://(127\\.0\\.0\\.1|localhost)", burl)) {
    return("plumber")
  }

  cli::cli_abort(c(
    "ToxValDB has no public REST API.",
    "i" = "Use {.code toxval_server()(1)} for local DuckDB access.",
    "i" = "Use {.code toxval_server()(2)} for a self-hosted Plumber instance.",
    "i" = "Run {.code tox_install()} to set up the local database."
  ))
}

#' Default columns returned by tox_results()
#'
#' Returns the curated set of ~45 default columns: 35 universal + 10 key
#' moderate coverage columns.
#' @return A character vector of column names.
#' @keywords internal
.tox_default_cols <- function() {
  c(
    "dtxsid", "casrn", "name",
    "source", "sub_source", "source_url",
    "qc_status", "qc_category",
    "toxval_type", "toxval_type_original", "toxval_type_supercategory",
    "toxval_subtype", "toxval_subtype_original",
    "qualifier",
    "toxval_numeric", "toxval_numeric_original",
    "toxval_units", "toxval_units_original",
    "study_type", "study_type_original",
    "study_duration_class",
    "study_duration_value", "study_duration_value_original",
    "study_duration_units", "study_duration_units_original",
    "risk_assessment_class",
    "species_common", "latin_name", "species_supercategory", "species_original",
    "strain",
    "sex", "sex_original",
    "exposure_route", "exposure_route_original",
    "exposure_method", "exposure_method_original",
    "toxicological_effect", "toxicological_effect_category",
    "lifestage",
    "year", "original_year",
    "experimental_record",
    "source_hash",
    "study_group"
  )
}


# Simple utility functions ------------------------------------------------

#' List tables in the ToxValDB database
#'
#' @param con An optional `DBI::DBIConnection`. If `NULL`, uses the managed
#'   connection.
#' @return A character vector of table names.
#' @export
#' @family toxval
#' @examples
#' \dontrun{
#' tox_tables()
#' }
toxval_tables <- function(con = NULL) {
  route <- .tox_route()

  if (route == "duckdb") {
    con <- .tox_get_con(con)
    DBI::dbListTables(con)
  } else {
    burl <- Sys.getenv("toxval_burl()")
    resp <- httr2::request(burl) |>
      httr2::req_url_path_append("tables") |>
      httr2::req_perform()
    httr2::resp_body_json(resp, simplifyVector = TRUE)
  }
}


#' List fields in a ToxValDB table
#'
#' @param table_name A single character string naming the table.
#' @param con An optional `DBI::DBIConnection`.
#' @return A character vector of column names.
#' @export
#' @family toxval
#' @examples
#' \dontrun{
#' tox_fields("toxval")
#' }
toxval_fields <- function(table_name, con = NULL) {
  if (!is.character(table_name) || length(table_name) != 1L || !nzchar(table_name)) {
    cli::cli_abort("{.arg table_name} must be a single non-empty character string.")
  }

  route <- .tox_route()

  if (route == "duckdb") {
    con <- .tox_get_con(con)
    DBI::dbListFields(con, table_name)
  } else {
    burl <- Sys.getenv("toxval_burl()")
    resp <- httr2::request(burl) |>
      httr2::req_url_path_append("fields", table_name) |>
      httr2::req_perform()
    httr2::resp_body_json(resp, simplifyVector = TRUE)
  }
}


#' ToxValDB database health check
#'
#' Returns status information about the ToxValDB database including version
#' label and file size.
#'
#' @param con An optional `DBI::DBIConnection`.
#' @return A named list with `status`, `db_path`, `version_label`,
#'   `row_count`, and `db_size_mb`.
#' @export
#' @family toxval
#' @examples
#' \dontrun{
#' tox_health()
#' }
toxval_health <- function(con = NULL) {
  route <- .tox_route()

  if (route == "duckdb") {
    con <- .tox_get_con(con)
    db_path <- Sys.getenv("toxval_burl()")

    meta <- tryCatch(
      {
        DBI::dbGetQuery(con,
          "SELECT version_label, row_count FROM _metadata WHERE is_latest = TRUE LIMIT 1"
        )
      },
      error = function(e) data.frame(version_label = NA_character_, row_count = NA_integer_)
    )

    list(
      status = "ok",
      db_path = db_path,
      version_label = if (nrow(meta) > 0) meta$version_label[[1]] else NA_character_,
      row_count = if (nrow(meta) > 0) meta$row_count[[1]] else NA_integer_,
      db_size_mb = round(file.size(db_path) / (1024 * 1024), 2)
    )
  } else {
    burl <- Sys.getenv("toxval_burl()")
    resp <- httr2::request(burl) |>
      httr2::req_url_path_append("health-check") |>
      httr2::req_perform()
    httr2::resp_body_json(resp)
  }
}


#' List ToxValDB data sources
#'
#' Returns the distinct source names available in the ToxValDB database.
#'
#' @param con An optional `DBI::DBIConnection`.
#' @return A character vector of source names, sorted alphabetically.
#' @export
#' @family toxval
#' @examples
#' \dontrun{
#' tox_sources()
#' }
toxval_sources <- function(con = NULL) {
  route <- .tox_route()

  if (route == "duckdb") {
    con <- .tox_get_con(con)
    result <- DBI::dbGetQuery(con, "SELECT DISTINCT source FROM toxval ORDER BY source")
    result$source
  } else {
    burl <- Sys.getenv("toxval_burl()")
    resp <- httr2::request(burl) |>
      httr2::req_url_path_append("sources") |>
      httr2::req_perform()
    httr2::resp_body_json(resp, simplifyVector = TRUE)
  }
}


#' Search ToxValDB by DTXSID
#'
#' Searches the `toxval` table by one or more DTXSIDs and returns matching
#' records with the default column set.
#'
#' @param dtxsid A character vector of DTXSIDs (e.g., `"DTXSID7020182"`).
#' @param limit Maximum number of rows to return. Default 1000.
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble of matching records (default columns).
#' @export
#' @family toxval
#' @examples
#' \dontrun{
#' toxval_search("DTXSID7020182")
#' toxval_search(c("DTXSID7020182", "DTXSID3021392"))
#' }
toxval_search <- function(dtxsid,
                       limit = 1000L,
                       con = NULL) {
  if (!is.character(dtxsid) || length(dtxsid) == 0L || !all(nzchar(dtxsid))) {
    cli::cli_abort("{.arg dtxsid} must be a non-empty character vector.")
  }

  dtxsid <- unique(dtxsid)
  route <- .tox_route()

  if (route == "plumber") {
    burl <- Sys.getenv("toxval_burl()")
    resp <- httr2::request(burl) |>
      httr2::req_url_path_append("search") |>
      httr2::req_body_json(list(dtxsid = dtxsid, limit = as.integer(limit))) |>
      httr2::req_perform()
    return(httr2::resp_body_json(resp, simplifyVector = TRUE) |>
      tibble::as_tibble())
  }

  con <- .tox_get_con(con)

  default_cols <- .tox_default_cols()
  col_select <- paste(default_cols, collapse = ", ")

  placeholders <- paste(rep("?", length(dtxsid)), collapse = ", ")
  sql <- paste0(
    "SELECT ", col_select, " FROM toxval WHERE dtxsid IN (", placeholders, ") LIMIT ?"
  )
  result <- DBI::dbGetQuery(con, sql, params = c(as.list(dtxsid), list(as.integer(limit))))
  tibble::as_tibble(result)
}


# tox_results — main query engine ----------------------------------------

#' Query ToxValDB results
#'
#' The primary query function for the ToxValDB database. Filters toxicological
#' values by chemical identifier (DTXSID, CASRN), source, toxval type, species,
#' or human/eco classification. Returns a tibble with curated default columns
#' (~45) or all columns.
#'
#' @param dtxsid Character vector of DTXSIDs to filter by.
#' @param casrn Character vector of CAS registry numbers to filter by.
#' @param source Character vector of source names (e.g., `"IRIS"`, `"ATSDR MRLs"`).
#' @param toxval_type Character vector of toxval types (e.g., `"RfD"`, `"RfC"`).
#' @param species Character vector of species names. Matched against both
#'   `species_common` and `latin_name`.
#' @param human_eco Character vector of human/eco classifications.
#' @param qc_status QC filter mode. One of:
#'   - `"pass_or_not_determined"` (default): exclude rows where qc_status
#'     starts with "fail"
#'   - `"pass"`: only rows with qc_status exactly "pass"
#'   - `"all"`: no QC filtering
#' @param cols Column selection mode. `"default"` returns ~45 curated columns;
#'   `"all"` returns all columns.
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble of ToxValDB results.
#' @export
#' @family toxval
#' @examples
#' \dontrun{
#' # Query by CASRN (Formaldehyde)
#' tox_results(casrn = "50-00-0")
#'
#' # Query by source
#' tox_results(source = "IRIS")
#'
#' # Query by DTXSID with all columns
#' tox_results(dtxsid = "DTXSID7020182", cols = "all")
#' }
toxval_results <- function(dtxsid = NULL,
                        casrn = NULL,
                        source = NULL,
                        toxval_type = NULL,
                        species = NULL,
                        human_eco = NULL,
                        qc_status = c("pass_or_not_determined", "pass", "all"),
                        cols = c("default", "all"),
                        con = NULL) {
  qc_status <- match.arg(qc_status)
  cols <- match.arg(cols)

  # Guard clause — prevent full-table scans
  if (
    is.null(dtxsid) &&
    is.null(casrn) &&
    is.null(source) &&
    is.null(toxval_type) &&
    is.null(species)
  ) {
    cli::cli_abort(
      "At least one filter parameter must be provided to avoid returning the entire database."
    )
  }

  route <- .tox_route()

  if (route == "plumber") {
    return(.tox_results_plumber(
      dtxsid = dtxsid, casrn = casrn, source = source,
      toxval_type = toxval_type, species = species,
      human_eco = human_eco, qc_status = qc_status, cols = cols
    ))
  }

  # DuckDB path
  con <- .tox_get_con(con)

  query <- dplyr::tbl(con, "toxval")

  # 1. QC filter
  if (qc_status == "pass_or_not_determined") {
    query <- query |>
      dplyr::filter(
        is.na(.data$qc_status) |
        !stringr::str_starts(.data$qc_status, "fail")
      )
  } else if (qc_status == "pass") {
    query <- query |>
      dplyr::filter(.data$qc_status == "pass")
  }
  # "all" → no filter

  # 2. DTXSID filter
  if (!is.null(dtxsid) && length(dtxsid) > 0) {
    dtxsid_vals <- unique(dtxsid)
    query <- query |> dplyr::filter(.data$dtxsid %in% dtxsid_vals)
  }

  # 3. CASRN filter
  if (!is.null(casrn) && length(casrn) > 0) {
    casrn_vals <- unique(casrn)
    query <- query |> dplyr::filter(.data$casrn %in% casrn_vals)
  }

  # 4. Source filter
  if (!is.null(source) && length(source) > 0) {
    source_vals <- unique(source)
    query <- query |> dplyr::filter(.data$source %in% source_vals)
  }

  # 5. Toxval type filter
  if (!is.null(toxval_type) && length(toxval_type) > 0) {
    type_vals <- unique(toxval_type)
    query <- query |> dplyr::filter(.data$toxval_type %in% type_vals)
  }

  # 6. Species filter (match against both species_common and latin_name)
  if (!is.null(species) && length(species) > 0) {
    species_vals <- unique(species)
    query <- query |>
      dplyr::filter(
        .data$species_common %in% species_vals |
        .data$latin_name %in% species_vals
      )
  }

  # 7. Human/eco filter
  if (!is.null(human_eco) && length(human_eco) > 0) {
    he_vals <- unique(human_eco)
    query <- query |> dplyr::filter(.data$human_eco %in% he_vals)
  }

  # 8. Column selection
  if (cols == "default") {
    default_cols <- .tox_default_cols()
    query <- query |> dplyr::select(dplyr::any_of(default_cols))
  }

  # 9. Collect
  dplyr::collect(query) |>
    tibble::as_tibble()
}


#' Send results query to ToxValDB Plumber API
#' @keywords internal
#' @noRd
.tox_results_plumber <- function(dtxsid, casrn, source, toxval_type,
                                  species, human_eco, qc_status, cols) {
  burl <- Sys.getenv("toxval_burl()")

  body <- list(
    dtxsid = dtxsid,
    casrn = casrn,
    source = source,
    toxval_type = toxval_type,
    species = species,
    human_eco = human_eco,
    qc_status = qc_status,
    cols = cols
  )
  # Drop NULLs
  body <- body[!vapply(body, is.null, logical(1))]

  resp <- tryCatch(
    httr2::request(burl) |>
      httr2::req_url_path_append("results") |>
      httr2::req_body_json(body) |>
      httr2::req_perform(),
    error = function(e) {
      cli::cli_abort(c(
        "ToxValDB Plumber request failed.",
        "x" = conditionMessage(e),
        "i" = "Is the Plumber server running? Check {.code toxval_server()(2)}."
      ))
    }
  )

  httr2::resp_body_json(resp, simplifyVector = TRUE) |>
    tibble::as_tibble()
}
