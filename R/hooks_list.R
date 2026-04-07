# List Hook Primitives
# Hooks for chemical list operations

#' Uppercase query parameter
#'
#' Pre-request hook that converts query parameter to uppercase.
#' The CompTox API expects list names in uppercase.
#'
#' @param data Hook data structure with list(params = list(query = ...))
#' @return Modified data with uppercased query
#' @noRd
uppercase_query <- function(data) {
  data$params$query <- toupper(data$params$query)
  return(data)
}

#' Extract DTXSIDs if requested
#'
#' Post-response hook that extracts DTXSIDs from list results when requested.
#' Handles duplicate names (multiple results) by collecting all dtxsids fields,
#' splits comma-separated strings, and deduplicates.
#'
#' @param data Hook data structure with list(result = ..., params = list(extract_dtxsids = ...))
#' @return Character vector of DTXSIDs if extract_dtxsids=TRUE, original result otherwise
#' @noRd
extract_dtxsids_if_requested <- function(data) {
  if (!isTRUE(data$params$extract_dtxsids)) {
    return(data$result)
  }

  dat <- data$result

  # Guard: check if dtxsids field exists in response
  has_dtxsids <- "dtxsids" %in% names(dat)
  if (!has_dtxsids) {
    cli::cli_warn("No {.field dtxsids} field found in response. Use {.code projection = 'chemicallistwithdtxsids'} to include DTXSIDs.")
    return(dat)
  }

  # Tibble result (tidy=TRUE, one or more queries)
  if (tibble::is_tibble(dat)) {
    dtxsids <- dat$dtxsids %>%
      stringr::str_split(pattern = '\\s*;\\s*') %>%
      unlist() %>%
      unique()
    return(tibble::tibble(dtxsid = dtxsids))
  }

  # Named list result (tidy=FALSE) with duplicate names (multiple results)
  if (anyDuplicated(names(dat)) > 0) {
    dtxsid_indices <- which(names(dat) == "dtxsids")
    dtxsids <- dat[dtxsid_indices] %>%
      purrr::map(~ stringr::str_split(.x, pattern = '\\s*;\\s*')) %>%
      unlist() %>%
      unique()
  } else {
    # Single named list result
    dtxsids <- dat$dtxsids %>%
      stringr::str_split(pattern = '\\s*;\\s*') %>%
      unlist() %>%
      unique()
  }

  return(tibble::tibble(dtxsid = dtxsids))
}

#' Transform hook for ct_lists_all
#'
#' Transform hook that wraps ct_chemical_list_all with projection and coerce logic.
#' This replaces the default generic_request call for ct_lists_all.
#'
#' @param data Hook data structure with list(params = list(return_dtxsid = ..., coerce = ...))
#' @return Tibble of lists or named list if coerced
#' @noRd
lists_all_transform <- function(data) {
  # Determine projection from params
  projection <- if (!isTRUE(data$params$return_dtxsid)) {
    "chemicallistall"
  } else {
    "chemicallistwithdtxsids"
  }

  # Call generic_request directly to avoid recursion
  df <- generic_request(
    endpoint = "chemical/list/all",
    method = "GET",
    batch_limit = 0,
    projection = projection
  )

  # Show success message
  cli::cli_alert_success("{nrow(df)} lists found!")

  # Handle coercion if requested
  if (isTRUE(data$params$return_dtxsid) && isTRUE(data$params$coerce)) {
    cli::cli_alert_warning("Coercing DTXSID strings per list to list-column!")

    df <- df %>%
      split(.$listName) %>%
      purrr::map(., as.list) %>%
      purrr::map(., ~ {
        .x$dtxsids <- stringr::str_split(.x$dtxsids, pattern = ",") %>%
          purrr::pluck(1)
        .x
      })
  } else if (!isTRUE(data$params$return_dtxsid) && isTRUE(data$params$coerce)) {
    cli::cli_alert_warning("You need to request DTXSIDs to coerce!")
  }

  return(df)
}

#' Format compound list result
#'
#' Post-response hook for ct_compound_in_list that formats the result
#' with informative CLI messages.
#'
#' @param data Hook data structure with list(result = ..., params = list(query = ...))
#' @return Formatted result with list names per query
#' @noRd
format_compound_list_result <- function(data) {
  results <- data$result
  query <- data$params$query

  # Extract the first element from each result (list of list names)
  df <- results %>%
    purrr::map(~ {
      if (is.list(.x) && length(.x) > 0) {
        list_names <- purrr::pluck(.x, 1)
        cli::cli_alert_success('{length(list_names)} lists found!')
        return(list_names)
      } else {
        cli::cli_alert_warning('No lists found')
        return(NULL)
      }
    }) %>%
    purrr::set_names(query) %>%
    purrr::compact()

  return(df)
}
