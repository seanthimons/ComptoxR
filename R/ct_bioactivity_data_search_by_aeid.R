#' Get data for a batch of AEIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_aeid_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_aeid_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "bioactivity/data/search/by-aeid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get data by AEID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param aeid aeid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_aeid(aeid = 3032L)
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_aeid <- function(aeid) {
  if (base::is.null(aeid)) {
    base::stop("Required input: aeid")
  }
  .api_validation$parameter_values(
    base::list("aeid" = aeid),
    list(aeid = list(type = "array", items = list(format = "int32", type = "integer"))),
    .api_validation$body_value,
    c(aeid = "path")
  )
  params <- base::list("aeid" = aeid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/data/search/by-aeid/{aeid}",
      path_params = base::list("aeid" = params[["aeid"]]),
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
      params["aeid"] <- base::list(chunk)
      send(params)
    },
    params[["aeid"]],
    1L,
    on_error = "drop"
  )
}
