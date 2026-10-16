#' Get data for a batch of M4IDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_m4id_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_m4id_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "bioactivity/data/search/by-m4id/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get data by M4ID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param m4id m4id Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_m4id(m4id = 7826737L)
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_m4id <- function(m4id) {
  if (base::is.null(m4id)) {
    base::stop("Required input: m4id")
  }
  .api_validation$parameter_values(
    base::list("m4id" = m4id),
    list(m4id = list(type = "array", items = list(format = "int32", type = "integer"))),
    .api_validation$body_value,
    c(m4id = "path")
  )
  params <- base::list("m4id" = m4id)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/data/search/by-m4id/{m4id}",
      path_params = base::list("m4id" = params[["m4id"]]),
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
      params["m4id"] <- base::list(chunk)
      send(params)
    },
    params[["m4id"]],
    1L,
    on_error = "drop"
  )
}
