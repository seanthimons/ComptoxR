# Post-response hooks for EPI Suite (epi_*) wrappers.
#
# epi_* functions route through generic_request with tidy = FALSE, so the raw
# response is returned as a nested list. generic_request wraps a single
# static-endpoint response in a length-1, unnamed list (carrying a
# query = "_static_" attribute). These hooks unwrap that envelope and give each
# endpoint the shape callers expect, mirroring the ct_*/chemi_* convention of
# folding response shaping into a post_response hook rather than a separate
# extractor function.

#' Unwrap a single EPI Suite result object
#'
#' Post-response hook for epi_submit and the epi_ecosar_* endpoints. Strips the
#' length-1 static-endpoint envelope generic_request adds and drops the internal
#' `query` attribute, returning the named list of result modules.
#'
#' @param data Hook data structure: list(result = ..., params = list(...)).
#' @return The inner named result list.
#' @noRd
unwrap_epi_result <- function(data) {
  res <- data$result

  if (is.list(res) && length(res) == 1 && is.null(names(res))) {
    res <- res[[1]]
  }
  attr(res, "query") <- NULL

  res
}

#' Bind EPI Suite search hits into a tibble
#'
#' Post-response hook for epi_search. The /search endpoint returns an array of
#' {name, smiles, cas} records; flatten them into one tibble (NA for any missing
#' field), matching the tabular shape the old epi_suite_search returned.
#'
#' @param data Hook data structure: list(result = ..., params = list(query = ...)).
#' @return A tibble of search hits (empty tibble when there are no matches).
#' @noRd
format_epi_search_result <- function(data) {
  res <- data$result

  # A single-hit response can arrive wrapped in a length-1 envelope.
  if (is.list(res) && length(res) == 1 && is.null(names(res)) && is.list(res[[1]]) && is.null(res[[1]]$name)) {
    res <- res[[1]]
  }

  if (!is.list(res) || length(res) == 0) {
    cli::cli_alert_warning("No chemicals found!")
    return(tibble::tibble())
  }

  out <- purrr::map(res, function(rec) {
    rec[vapply(rec, is.null, logical(1))] <- NA
    tibble::as_tibble(rec)
  }) %>%
    purrr::list_rbind()

  cli::cli_alert_success("{nrow(out)} chemical{?s} found!")
  out
}
