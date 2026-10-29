#' @title Get Similar Compounds by DTXSID
#'
#' @description
#' `r lifecycle::badge("questioning")`
#'
#' @param query A character vector of DTXSIDs.
#' @param similarity The similarity threshold, a numeric value between 0 and 1. Optional, defaults to 0.8.
#'
#' @returns A tibble of similar compounds, or an empty tibble if no similar compounds are found.
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' ct_similar(query = "DTXSID7020182", similarity = 0.8)
#' }
ct_similar <- function(query, similarity = 0.8) {
  # Run pre-request hooks (validates similarity range)
  req_data <- run_hook("ct_similar", "pre_request", list(params = list(query = query, similarity = similarity)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("similarity" %in% names(req_data$params)) {
    similarity <- req_data$params[["similarity"]]
  }

  query <- .ct_legacy_query(query)
  result <- .ct_request_each(
    function(chunk) {
      .ct_request(
        method = "GET",
        path = "/similar-compound/by-dtxsid/{query}/{similarity}",
        path_params = list(query = chunk, similarity = similarity),
        query = list(),
        body = NULL,
        response_policy = ".ct_tidy",
        server = list(url = "https://comptox.epa.gov/dashboard-api"),
        auth = list(list(list(
          scheme = "ctx",
          type = "apiKey",
          location = "header",
          name = "x-api-key",
          envvar = "ctx_api_key"
        )))
      )
    },
    query,
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )

  return(result)
}
