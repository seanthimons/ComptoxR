#' Get data for a batch of SPIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_spid_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_spid_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "bioactivity/data/search/by-spid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get data by SPID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param spid spid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_spid(spid = "EPAPLT0232A03")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_spid <- function(spid) {
  if (base::is.null(spid)) {
    base::stop("Required input: spid")
  }
  .api_validation$parameter_values(
    base::list("spid" = spid),
    list(spid = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(spid = "path")
  )
  params <- base::list("spid" = spid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/data/search/by-spid/{spid}",
      path_params = base::list("spid" = params[["spid"]]),
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
      params["spid"] <- base::list(chunk)
      send(params)
    },
    params[["spid"]],
    1L,
    on_error = "drop"
  )
}
