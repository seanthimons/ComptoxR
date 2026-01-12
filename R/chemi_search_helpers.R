# Internal helper functions for chemi_search
# These are not exported

#' Get MOL string for search operations
#'
#' @param query DTXSID, SMILES, or existing MOL string
#' @param search_type The search type being performed (lowercase)
#' @return MOL string suitable for API payload
#' @keywords internal
get_mol_for_search <- function(query, search_type) {
  # Return empty MOL placeholder for hazard/features searches
  if (search_type %in% c("hazard", "features")) {
    return(.empty_mol_string)
  }

  # Return NULL for mass-only searches
  if (search_type == "mass") {
    return(NULL)
  }

  # If query is NULL or empty, abort
 if (is.null(query) || length(query) == 0 || query == "") {
    cli::cli_abort("Query is required for {search_type} searches")
  }

  # Check if already a MOL string (contains "M  END")
  if (grepl("M\\s+END", query)) {
    return(query)
  }

  # Fetch MOL file via ct_chemical_file_mol
  if (as.logical(Sys.getenv("run_verbose", "FALSE"))) {
    cli::cli_alert_info("Fetching MOL file for {.val {query}}")
  }

  ct_chemical_file_mol(dtxsid = query)
}

#' Build params list for SearchRequest
#'
#' @param search_type Search type (lowercase)
#' @param similarity_type Similarity metric type
#' @param min_similarity Minimum similarity threshold
#' @param hazard_name Hazard name (short form)
#' @param min_toxicity Minimum toxicity level
#' @param min_authority Minimum authority level (short form)
#' @param mass_type Mass type (short form)
#' @param min_mass Minimum mass value
#' @param max_mass Maximum mass value
#' @param filter_features Whether to apply feature filters
#' @param feature_filters Named logical vector of feature filters
#' @param element_include Elements to include
#' @param element_exclude Elements to exclude
#' @param exclude_all_others Whether to exclude all elements not in element_include
#' @param limit Maximum results to return
#' @return Named list of API parameters
#' @keywords internal
build_search_params <- function(
    search_type,
    similarity_type = NULL,
    min_similarity = NULL,
    hazard_name = NULL,
    min_toxicity = NULL,
    min_authority = NULL,
    mass_type = NULL,
    min_mass = NULL,
    max_mass = NULL,
    filter_features = FALSE,
    feature_filters = NULL,
    element_include = NULL,
    element_exclude = NULL,
    exclude_all_others = FALSE,
    limit = 50
) {
  params <- list(limit = limit)

  # Similarity params (for SIMILAR search type)
  if (search_type == "similar") {
    if (!is.null(similarity_type)) {
      params[["similarity-type"]] <- .similarity_type_map[similarity_type]
    }
    if (!is.null(min_similarity)) {
      params[["min-similarity"]] <- min_similarity
    }
  }

  # Hazard params (for HAZARD search type)
  if (search_type == "hazard") {
    if (!is.null(hazard_name)) {
      params[["hazard-name"]] <- .hazard_name_map[hazard_name]
    }
    if (!is.null(min_toxicity) && length(min_toxicity) == 1) {
      params[["min-toxicity"]] <- min_toxicity
    }
    if (!is.null(min_authority) && length(min_authority) == 1) {
      params[["min-authority"]] <- .authority_map[min_authority]
    }
  }

  # Mass params
  if (!is.null(mass_type) && length(mass_type) == 1) {
    params[["mass-type"]] <- .mass_type_map[mass_type]
  }
  if (!is.null(min_mass)) {
    params[["min-mass"]] <- min_mass
  }
  if (!is.null(max_mass)) {
    params[["max-mass"]] <- max_mass
  }

  # Feature filters
  if (filter_features && !is.null(feature_filters)) {
    for (filter_name in names(feature_filters)) {
      if (filter_name %in% .feature_filter_names) {
        params[[paste0("filter-", filter_name)]] <- feature_filters[[filter_name]]
      }
    }
  }

  # Element filters
  if (!is.null(element_include)) {
    params[["include-elements"]] <- paste(element_include, collapse = ",")
  }

  # Handle element exclusion
  if (!is.null(element_exclude) || exclude_all_others) {
    excluded <- expand_element_exclusion(element_include, element_exclude, exclude_all_others)
    if (!is.null(excluded) && length(excluded) > 0) {
      params[["exclude-elements"]] <- excluded
    }
  }

  return(params)
}

#' Expand element exclusion list
#'
#' @param element_include Elements being included
#' @param element_exclude Elements to explicitly exclude
#' @param exclude_all_others If TRUE, exclude all elements except those in element_include
#' @return Comma-separated string of elements to exclude, or NULL
#' @keywords internal
expand_element_exclusion <- function(element_include, element_exclude, exclude_all_others) {
  if (exclude_all_others && !is.null(element_include)) {
    # Get all elements from periodic table, exclude those in element_include
    all_elements <- ComptoxR::pt$elements %>%
      dplyr::filter(as.numeric(Number) <= 103) %>%
      dplyr::pull(Symbol) %>%
      unique() %>%
      sort()

    excluded <- setdiff(all_elements, element_include)
    return(paste(excluded, collapse = ", "))
  }

  if (!is.null(element_exclude)) {
    return(paste(element_exclude, collapse = ", "))
  }

  return(NULL)
}

#' Validate search inputs
#'
#' @param search_type The search type
#' @param query The query value
#' @param hazard_name Hazard name if provided
#' @param min_similarity Minimum similarity if provided
#' @keywords internal
validate_search_inputs <- function(search_type, query, hazard_name = NULL, min_similarity = NULL) {
  # Search type is required and must be single value
  if (is.null(search_type) || length(search_type) != 1) {
    cli::cli_abort("search_type must be a single value")
  }

  # Validate search_type is known
  if (!search_type %in% names(.search_type_map)) {
    cli::cli_abort(
      "Invalid search_type {.val {search_type}}. Must be one of: {.val {names(.search_type_map)}}"
    )
  }

  # Query required for certain search types
  query_required <- c("exact", "substructure", "similar")
  if (search_type %in% query_required && (is.null(query) || query == "")) {
    cli::cli_abort("{.val {search_type}} search requires a query")
  }

  # Hazard name validation
  if (!is.null(hazard_name) && !hazard_name %in% names(.hazard_name_map)) {
    cli::cli_abort(
      "Invalid hazard_name {.val {hazard_name}}. Must be one of: {.val {names(.hazard_name_map)}}"
    )
  }

  # Min similarity validation
  if (!is.null(min_similarity)) {
    if (!is.numeric(min_similarity) || min_similarity < 0 || min_similarity > 1) {
      cli::cli_abort("min_similarity must be a number between 0 and 1")
    }
  }

  invisible(TRUE)
}

#' Process search API response
#'
#' @param body The parsed JSON response body
#' @param original_query The original query value (for relationship column)
#' @return A tibble of search results
#' @keywords internal
process_search_response <- function(body, original_query) {
  total_count <- purrr::pluck(body, "totalRecordsCount", .default = 0)
  records <- purrr::pluck(body, "records", .default = list())

  if (length(records) == 0) {
    cli::cli_alert_warning("No compounds found")
    return(tibble::tibble())
  }

  df <- records %>%
    purrr::map(tibble::as_tibble) %>%
    purrr::list_rbind()

  # Add relationship column for similarity searches
  if ("similarity" %in% colnames(df) && !is.null(original_query)) {
    df <- df %>%
      dplyr::mutate(
        relationship = dplyr::if_else(
          .data$sid == original_query,
          "parent",
          "child"
        )
      )
  }

  cli::cli_alert_success("{total_count} compounds found!")
  return(df)
}
