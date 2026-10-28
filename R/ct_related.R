#' Get related substances from the EPA CompTox dashboard
#'
#' @description
#' `r lifecycle::badge("questioning")`
#'
#' This wrapper intentionally uses the legacy CompTox Dashboard
#' `dashboard-api/ccdapp2` route. The production `ctx-api` route for
#' `related-substances/search/by-dtxsid` is not currently available, while the
#' legacy endpoint still serves this data.
#'
#' @param query A character vector of DTXSIDs to query.
#' @param inclusive Boolean to only return results within all of the queried compounds. Valid for over one compound.
#' @export
#'
#' @return A list of data frames containing related substances.
#' @export
#'
#' @examples
#' \dontrun{
#' ct_related(query = "DTXSID0024842")
#' }
#'

ct_related <- function(query, inclusive = FALSE) {
  # Validation
  if (length(query) == 0) {
    cli::cli_abort("Query must be a character vector of DTXSIDs.")
  }

  if (inclusive == TRUE & length(query) == 1) {
    cli::cli_abort("Inclusive option only valid for multiple compounds")
  }

  run_verbose <- .run_verbose_enabled()
  if (run_verbose) {
    cli::cli_rule(left = "Related substances payload options")
    cli::cli_dl(
      c(
        "Number of compounds" = "{length(query)}",
        "Inclusive" = "{inclusive}"
      )
    )
    cli::cli_rule()
    cli::cli_end()
  }

  # Legacy Dashboard ccdapp2 route: production ctx-api does not expose this
  # endpoint yet, and it takes the DTXSID as a query parameter, so each item
  # is a separate unauthenticated request returning the raw JSON body.
  results <- purrr::map(
    query,
    function(dtxsid) {
      # One failed DTXSID warns and is skipped rather than aborting the call.
      tryCatch(
        .ct_request(
          method = "GET",
          path = "/related-substances/search/by-dtxsid",
          path_params = list(),
          query = list(id = dtxsid),
          body = NULL,
          server = list(url = "https://comptox.epa.gov/dashboard-api/ccdapp2")
        ),
        error = function(e) {
          cli::cli_warn("Related substances request failed for {dtxsid}: {conditionMessage(e)}")
          NULL
        }
      )
    },
    .progress = run_verbose
  ) %>%
    purrr::set_names(query)

  # Post-process: extract nested data, filter parent compound
  # This matches original behavior exactly
  data <- results %>%
    purrr::map(function(result) {
      if (is.list(result) && "data" %in% names(result)) {
        return(result$data)
      }

      if (
        is.list(result) &&
          length(result) > 0 &&
          is.list(result[[1]]) &&
          "data" %in% names(result[[1]])
      ) {
        return(result[[1]]$data)
      }

      list()
    }) %>%
    purrr::map(
      ~ purrr::map(
        .,
        ~ purrr::keep(.x, names(.x) %in% c("dtxsid", "relationship")) %>%
          tibble::as_tibble()
      ) %>%
        purrr::list_rbind()
    ) %>%
    purrr::list_rbind(names_to = "query")

  # Handle empty results
  if (nrow(data) == 0 || !"dtxsid" %in% names(data)) {
    return(tibble::tibble())
  }

  data <- data %>%
    dplyr::rename(child = dtxsid) %>%
    dplyr::filter(child != query) # Remove parent compound

  # Apply inclusive filtering if requested
  if (inclusive == TRUE) {
    data <- dplyr::filter(data, query %in% query & child %in% query)
  }

  return(data)
}
