#' Get summary data for a batch of DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_genetox_search_bulk(query = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_genetox_search_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "hazard/genetox/summary/search/by-dtxsid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get summary data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_genetox_search(dtxsid = "DTXSID0021125")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_genetox_search <- function(dtxsid) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid),
    list(dtxsid = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(dtxsid = "path")
  )
  params <- base::list("dtxsid" = dtxsid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/hazard/genetox/summary/search/by-dtxsid/{dtxsid}",
      path_params = base::list("dtxsid" = params[["dtxsid"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_tidy",
      server = list(url = "https://comptox.epa.gov/ctx-api"),
      server_resolver = list(name = ".ct_server_url", key = "ctx_burl"),
      auth = list(list(list(
        scheme = "ctx",
        type = "apiKey",
        location = "header",
        name = "x-api-key",
        envvar = "ctx_api_key"
      )))
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    1L,
    on_error = "drop"
  )
}
