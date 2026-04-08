# ECOTOX Local Database — Core Query Functions
# -----------------------------------------------

# dbplyr is needed for dplyr::tbl() to translate to SQL on DBI connections.
# This explicit import prevents the "Namespace in Imports field not imported
# from: 'dbplyr'" R CMD check warning.
#' @importFrom dbplyr sql_render
NULL

# Internal helpers --------------------------------------------------------

#' Determine ECOTOX routing mode
#'
#' Checks `eco_burl` env var and returns the access mode.
#' @return `"duckdb"` or `"plumber"`.
#' @keywords internal
.eco_route <- function() {
  burl <- Sys.getenv("eco_burl")

  if (nzchar(burl) && grepl("\\.duckdb$", burl) && file.exists(burl)) {
    return("duckdb")
  }

  if (nzchar(burl) && grepl("^https?://(127\\.0\\.0\\.1|localhost)", burl)) {
    return("plumber")
  }

  cli::cli_abort(c(
    "ECOTOX has no public REST API.",
    "i" = "Use {.code eco_server(4)} for local DuckDB access.",
    "i" = "Use {.code eco_server(3)} for a self-hosted Plumber instance.",
    "i" = "Run {.code eco_install()} to set up the local database."
  ))
}


# Simple utility functions ------------------------------------------------

#' List tables in the ECOTOX database
#'
#' @param con An optional `DBI::DBIConnection`. If `NULL`, uses the managed
#'   connection.
#' @return A character vector of table names.
#' @export
#' @family ecotox
#' @examples
#' \dontrun{
#' eco_tables()
#' }
eco_tables <- function(con = NULL) {
  route <- .eco_route()

  if (route == "duckdb") {
    con <- .eco_get_con(con)
    DBI::dbListTables(con)
  } else {
    burl <- Sys.getenv("eco_burl")
    resp <- httr2::request(burl) |>
      httr2::req_url_path_append("all_tbls") |>
      httr2::req_perform()
    httr2::resp_body_json(resp, simplifyVector = TRUE)
  }
}


#' List fields in an ECOTOX table
#'
#' @param table_name A single character string naming the table.
#' @param con An optional `DBI::DBIConnection`.
#' @return A character vector of column names.
#' @export
#' @family ecotox
#' @examples
#' \dontrun{
#' eco_fields("tests")
#' }
eco_fields <- function(table_name, con = NULL) {
  if (!is.character(table_name) || length(table_name) != 1L || !nzchar(table_name)) {
    cli::cli_abort("{.arg table_name} must be a single non-empty character string.")
  }

  route <- .eco_route()

  if (route == "duckdb") {
    con <- .eco_get_con(con)
    DBI::dbListFields(con, table_name)
  } else {
    burl <- Sys.getenv("eco_burl")
    resp <- httr2::request(burl) |>
      httr2::req_url_path_append("fields", table_name) |>
      httr2::req_perform()
    httr2::resp_body_json(resp, simplifyVector = TRUE)
  }
}


#' Get the ECOTOX chemical inventory
#'
#' Returns the full `chemicals` table from the ECOTOX database.
#'
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble of chemical records.
#' @export
#' @family ecotox
#' @examples
#' \dontrun{
#' eco_inventory()
#' }
eco_inventory <- function(con = NULL) {
  route <- .eco_route()

  if (route == "duckdb") {
    con <- .eco_get_con(con)
    DBI::dbGetQuery(con, "SELECT * FROM chemicals") |>
      tibble::as_tibble()
  } else {
    burl <- Sys.getenv("eco_burl")
    resp <- httr2::request(burl) |>
      httr2::req_url_path_append("inventory") |>
      httr2::req_perform()
    httr2::resp_body_json(resp, simplifyVector = TRUE) |>
      tibble::as_tibble()
  }
}


#' ECOTOX database health check
#'
#' Returns status information about the ECOTOX database including version
#' date and file size.
#'
#' @param con An optional `DBI::DBIConnection`.
#' @return A named list with `status`, `db_path`, `version_date`, and
#'   `db_size_mb`.
#' @export
#' @family ecotox
#' @examples
#' \dontrun{
#' eco_health()
#' }
eco_health <- function(con = NULL) {
  route <- .eco_route()

  if (route == "duckdb") {
    con <- .eco_get_con(con)
    db_path <- Sys.getenv("eco_burl")

    # Try to get version date from versions table
    version_date <- tryCatch(
      {
        v <- DBI::dbGetQuery(con,
          "SELECT date FROM versions WHERE latest = TRUE LIMIT 1"
        )
        if (nrow(v) > 0) v$date[[1]] else NA_character_
      },
      error = function(e) NA_character_
    )

    list(
      status = "ok",
      db_path = db_path,
      version_date = version_date,
      db_size_mb = round(file.size(db_path) / (1024 * 1024), 2)
    )
  } else {
    burl <- Sys.getenv("eco_burl")
    resp <- httr2::request(burl) |>
      httr2::req_url_path_append("health-check") |>
      httr2::req_perform()
    httr2::resp_body_json(resp)
  }
}


#' Search ECOTOX species
#'
#' Searches the `species` table by common name, latin name, or eco group
#' using SQL `ILIKE` pattern matching.
#'
#' @param query A character string with SQL ILIKE wildcards (e.g.,
#'   `"Rainbow%"`).
#' @param field Which field to search. One of `"common_name"`,
#'   `"latin_name"`, or `"eco_group"`.
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble of matching species records.
#' @export
#' @family ecotox
#' @examples
#' \dontrun{
#' eco_species("Rainbow%")
#' eco_species("Oncorhynchus%", field = "latin_name")
#' }
eco_species <- function(query,
                        field = c("common_name", "latin_name", "eco_group"),
                        con = NULL) {
  field <- match.arg(field)
  route <- .eco_route()

  if (route == "plumber") {
    cli::cli_abort(c(
      "Species search is not available via the Plumber API.",
      "i" = "Use {.code eco_server(4)} for local DuckDB access."
    ))
  }

  con <- .eco_get_con(con)

  # field is from match.arg — safe to interpolate
  sql <- paste0("SELECT * FROM species WHERE ", field, " ILIKE ?")
  result <- DBI::dbGetQuery(con, sql, params = list(query))
  tibble::as_tibble(result)
}


# eco_results — main query engine ----------------------------------------

#' Query ECOTOX test results
#'
#' The primary query function for the ECOTOX database. Filters test results
#' by chemical (CAS number), species (common or latin name), endpoint,
#' ecological group, and species characteristic flags. Returns an enriched
#' tibble with metadata joins (exposure types, effects, lifestages,
#' application frequencies) and unit/duration conversions applied.
#'
#' @param casrn Character vector of CAS registry numbers to filter by.
#'   Dashes are stripped automatically.
#' @param common_name Character vector of common species names.
#' @param latin_name Character vector of latin species names.
#' @param endpoint Character vector of endpoint codes, or the special values
#'   `"all"` (no filter) or `"default"` (curated set of standard endpoints).
#' @param eco_group Character vector of ecological groups (e.g., `"Fish"`,
#'   `"Invertebrates"`).
#' @param invasive Logical; filter to invasive species only?
#' @param standard Logical; filter to standard test species only?
#' @param threatened Logical; filter to endangered/threatened species only?
#' @param test_cols Optional character vector of additional columns to select
#'   from the `tests` table.
#' @param results_cols Optional character vector of additional columns to
#'   select from the `results` table.
#' @param con An optional `DBI::DBIConnection`.
#' @return A tibble of enriched test results with concentration and duration
#'   conversions applied.
#' @export
#' @family ecotox
#' @examples
#' \dontrun{
#' # Query by CAS number (DDT)
#' eco_results(casrn = "50-29-3")
#'
#' # Query by species with default endpoints
#' eco_results(common_name = "Rainbow trout", endpoint = "default")
#'
#' # Query by eco group with custom endpoints
#' eco_results(eco_group = "Fish", endpoint = c("LC50", "EC50"))
#' }
eco_results <- function(casrn = NULL,
                        common_name = NULL,
                        latin_name = NULL,
                        endpoint = NULL,
                        eco_group = NULL,
                        invasive = FALSE,
                        standard = FALSE,
                        threatened = FALSE,
                        test_cols = NULL,
                        results_cols = NULL,
                        con = NULL) {
  # Guard clause — prevent full-table scans
  if (
    is.null(casrn) &&
      is.null(common_name) &&
      is.null(latin_name) &&
      is.null(endpoint) &&
      is.null(eco_group) &&
      !invasive &&
      !standard &&
      !threatened
  ) {
    cli::cli_abort(
      "At least one filter parameter must be provided to avoid returning the entire database."
    )
  }

  route <- .eco_route()

  if (route == "plumber") {
    return(.eco_results_plumber(
      casrn = casrn, common_name = common_name, latin_name = latin_name,
      endpoint = endpoint, eco_group = eco_group,
      invasive = invasive, standard = standard, threatened = threatened,
      test_cols = test_cols, results_cols = results_cols
    ))
  }

  # DuckDB path
  con <- .eco_get_con(con)

  query <- .eco_base_query(
    con,
    casrn = casrn, common_name = common_name, latin_name = latin_name,
    endpoint = endpoint, eco_group = eco_group,
    invasive = invasive, standard = standard, threatened = threatened,
    test_cols = test_cols, results_cols = results_cols
  )

  query <- .eco_enrich_metadata(query, con)
  query <- .eco_apply_conversions(query, con)

  df <- dplyr::collect(query)
  .eco_post_process(df)
}


#' Send results query to Plumber API
#' @keywords internal
#' @noRd
.eco_results_plumber <- function(casrn, common_name, latin_name,
                                  endpoint, eco_group,
                                  invasive, standard, threatened,
                                  test_cols, results_cols) {
  burl <- Sys.getenv("eco_burl")

  body <- list(
    casrn = casrn,
    common_name = common_name,
    latin_name = latin_name,
    endpoint = endpoint,
    eco_group = eco_group,
    invasive = invasive,
    standard = standard,
    threatened = threatened,
    test_cols = test_cols,
    results_cols = results_cols
  )
  # Drop NULLs
  body <- body[!vapply(body, is.null, logical(1))]

  resp <- httr2::request(burl) |>
    httr2::req_url_path_append("results") |>
    httr2::req_body_json(body) |>
    httr2::req_perform()

  httr2::resp_body_json(resp, simplifyVector = TRUE) |>
    tibble::as_tibble()
}


# DuckDB pipeline stages --------------------------------------------------

#' Build the base query: tests + species + chemicals + results with filters
#' @keywords internal
#' @noRd
.eco_base_query <- function(con,
                            casrn, common_name, latin_name,
                            endpoint, eco_group,
                            invasive, standard, threatened,
                            test_cols, results_cols) {
  base_test_cols <- c(
    "reference_number",
    "test_id",
    "test_cas",
    "species_number",
    "exposure_type",
    "test_type",
    "organism_lifestage",
    "application_freq_mean",
    "application_freq_unit"
  )

  base_result_cols <- c(
    "result_id",
    "test_id",
    "endpoint",
    "effect",
    "measurement",
    "obs_duration_mean",
    "obs_duration_min",
    "obs_duration_max",
    "obs_duration_unit",
    "conc1_type",
    "conc1_mean_op",
    "conc1_unit",
    "conc1_mean",
    "conc1_min",
    "conc1_max"
  )

  # Start with tests table
  result_query <- dplyr::tbl(con, "tests") |>
    dplyr::select(
      dplyr::all_of(base_test_cols),
      dplyr::contains("_duration_"),
      dplyr::any_of(test_cols)
    ) |>
    dplyr::inner_join(
      dplyr::tbl(con, "species") |>
        dplyr::select(
          "species_number", "common_name", "latin_name",
          "family", "genus", "species", "eco_group",
          "standard_test_species", "invasive_species",
          "endangered_threatened_species"
        ),
      by = "species_number"
    )

  # Chemical filtering — strip dashes from CAS numbers

  if (!is.null(casrn) && length(casrn) > 0) {
    casrn_cleaned <- unique(stringr::str_remove_all(casrn, "-"))
    result_query <- result_query |>
      dplyr::filter(.data$test_cas %in% casrn_cleaned)
  }

  # Join chemicals table
  result_query <- result_query |>
    dplyr::left_join(
      dplyr::tbl(con, "chemicals") |>
        dplyr::select(
          "cas_number", "chemical_name", "dtxsid",
          chemical_group = "ecotox_group"
        ),
      by = dplyr::join_by("test_cas" == "cas_number")
    ) |>
    dplyr::relocate(
      "chemical_name", "dtxsid", "chemical_group",
      .after = "test_cas"
    )

  # Species name filtering (OR condition)
  if (
    (!is.null(common_name) && length(common_name) > 0) ||
      (!is.null(latin_name) && length(latin_name) > 0)
  ) {
    species_filter_expr <- list()
    if (!is.null(common_name) && length(common_name) > 0) {
      species_filter_expr <- c(
        species_filter_expr,
        list(rlang::expr(.data$common_name %in% !!common_name))
      )
    }
    if (!is.null(latin_name) && length(latin_name) > 0) {
      species_filter_expr <- c(
        species_filter_expr,
        list(rlang::expr(.data$latin_name %in% !!latin_name))
      )
    }
    combined_expr <- Reduce(
      function(a, b) rlang::expr(!!a | !!b),
      species_filter_expr
    )
    result_query <- result_query |> dplyr::filter(!!combined_expr)
  }

  # Eco group filter
  if (!is.null(eco_group) && length(eco_group) > 0) {
    eg <- eco_group
    result_query <- result_query |>
      dplyr::filter(.data$eco_group %in% eg)
  }

  # Species characteristic flags
  if (invasive) {
    result_query <- result_query |>
      dplyr::filter(.data$invasive_species)
  }
  if (standard) {
    result_query <- result_query |>
      dplyr::filter(.data$standard_test_species)
  }
  if (threatened) {
    result_query <- result_query |>
      dplyr::filter(.data$endangered_threatened_species)
  }

  # Join results table
  result_query <- result_query |>
    dplyr::inner_join(
      dplyr::tbl(con, "results") |>
        dplyr::select(
          dplyr::all_of(base_result_cols),
          dplyr::any_of(results_cols)
        ),
      by = "test_id"
    )

  # Endpoint filtering
  if (!is.null(endpoint) && length(endpoint) > 0) {
    ep_str <- paste(endpoint, collapse = " ")
    if (ep_str == "all") {
      # No filtering
    } else if (ep_str == "default") {
      endpoint_regex <- paste0(
        "^EC50|^LC50|^LD50|LR50|^LOEC|^LOEL|NOEC|NOEL$|",
        "NR-ZERO|NR-LETH|AC50|\\(log\\)EC50|\\(log\\)LC50|\\(log\\)LOEC"
      )
      result_query <- result_query |>
        dplyr::filter(stringr::str_detect(.data$endpoint, endpoint_regex))
    } else {
      endpoint_regex <- paste(endpoint, collapse = "|")
      result_query <- result_query |>
        dplyr::filter(stringr::str_detect(.data$endpoint, endpoint_regex))
    }
  }

  result_query
}


#' Enrich query with metadata joins (exposure types, effects, lifestages)
#' @keywords internal
#' @noRd
.eco_enrich_metadata <- function(query, con) {
  # Value cleaning
  query <- query |>
    dplyr::mutate(
      common_name = stringr::str_squish(.data$common_name),
      dplyr::across(
        c("exposure_type", "measurement", "endpoint", "effect"),
        ~ stringr::str_remove_all(., "\\/|\\*|\\~")
      ),
      dplyr::across(
        c("obs_duration_mean", "obs_duration_min", "obs_duration_max"),
        ~ dplyr::sql(sprintf(
          "TRY_CAST(REGEXP_REPLACE(%s, '[\\*\\+]|\\s', '', 'g') AS DOUBLE)",
          dplyr::cur_column()
        ))
      ),
      dplyr::across(
        c("conc1_mean", "conc1_min", "conc1_max"),
        ~ dplyr::sql(sprintf(
          "TRY_CAST(REGEXP_REPLACE(%s, '[\\*\\+]|\\s', '', 'g') AS DOUBLE)",
          dplyr::cur_column()
        ))
      )
    )

  # Exposure types
  query <- query |>
    dplyr::left_join(
      dplyr::tbl(con, "app_exposure_types") |>
        dplyr::select(
          "exposure_group", "term",
          exposure_description = "description"
        ),
      by = dplyr::join_by("exposure_type" == "term")
    ) |>
    dplyr::left_join(
      dplyr::tbl(con, "app_exposure_type_groups") |>
        dplyr::select("term", exposure_name = "description"),
      by = dplyr::join_by("exposure_group" == "term")
    ) |>
    dplyr::relocate(
      "exposure_group", "exposure_description", "exposure_name",
      .after = "exposure_type"
    )

  # Effect groups and measurements
  query <- query |>
    dplyr::left_join(
      dplyr::tbl(con, "app_effect_groups_and_measurements") |>
        dplyr::select(
          "measurement_term", "measurement_name",
          "effect_code", effect_name = "effect",
          -"measurement_definition"
        ),
      by = dplyr::join_by(
        "effect" == "effect_code",
        "measurement" == "measurement_term"
      )
    ) |>
    dplyr::left_join(
      dplyr::tbl(con, "effect_groups_dictionary") |>
        dplyr::select(
          effect = "term", "effect_group",
          "super_effect_description"
        ),
      by = dplyr::join_by("effect" == "effect")
    ) |>
    dplyr::rename(effect_group_name = "super_effect_description") |>
    dplyr::relocate(
      "effect_group", "effect_group_name", "effect", "effect_name",
      "measurement", "measurement_name",
      .after = "endpoint"
    )

  # Lifestage codes + dictionary
  query <- query |>
    dplyr::left_join(
      dplyr::tbl(con, "lifestage_codes") |>
        dplyr::rename(org_lifestage = "description"),
      by = dplyr::join_by("organism_lifestage" == "code")
    ) |>
    dplyr::left_join(
      dplyr::tbl(con, "lifestage_dictionary"),
      by = dplyr::join_by("org_lifestage" == "org_lifestage")
    ) |>
    dplyr::relocate(
      "org_lifestage", "harmonized_life_stage",
      .after = "organism_lifestage"
    )

  # Application frequencies
  query <- query |>
    dplyr::left_join(
      dplyr::tbl(con, "app_application_frequencies") |>
        dplyr::rename(application_freq_name = "description"),
      by = dplyr::join_by("application_freq_unit" == "term")
    ) |>
    dplyr::relocate(
      "application_freq_name",
      .after = "application_freq_unit"
    )

  query
}


#' Apply unit and duration conversion joins
#' @keywords internal
#' @noRd
.eco_apply_conversions <- function(query, con) {
  query |>
    dplyr::left_join(
      dplyr::tbl(con, "unit_conversion"),
      by = dplyr::join_by("conc1_unit" == "orig")
    ) |>
    dplyr::left_join(
      dplyr::tbl(con, "duration_conversion"),
      by = dplyr::join_by("obs_duration_unit" == "code")
    )
}


#' Post-process collected results: compute derived concentration & duration
#' @keywords internal
#' @noRd
.eco_post_process <- function(df) {
  df |>
    dplyr::mutate(
      init_conc = dplyr::if_else(
        !is.na(.data$conc1_mean),
        .data$conc1_mean,
        sqrt(pmax(.data$conc1_min * .data$conc1_max, 0, na.rm = TRUE))
      ),
      final_conc = .data$init_conc * .data$conversion_factor_unit,
      obs_duration = dplyr::coalesce(
        .data$obs_duration_mean,
        .data$obs_duration_min,
        .data$obs_duration_max
      ) |> as.numeric(),
      final_obs_duration = .data$obs_duration * .data$conversion_factor_duration
    ) |>
    dplyr::relocate(
      "reference_number", "test_id", "result_id", "species_number",
      .before = "test_cas"
    )
}
