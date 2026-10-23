#' Get AEID by assay component endpoint name
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param endpoint endpoint
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_search_by_endpoint(endpoint = "CCTE_GLTED_hIYD")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay_search_by_endpoint <- function(endpoint) {
  if (base::is.null(endpoint)) {
    base::stop("Required input: endpoint")
  }
  .api_validation$parameter_values(
    base::list("endpoint" = endpoint),
    list(endpoint = list(type = "string")),
    .api_validation$body_value,
    c(endpoint = "query")
  )
  params <- base::list("endpoint" = endpoint)
  if (base::is.character(params[["endpoint"]]) && base::any(!base::nzchar(params[["endpoint"]]))) {
    base::stop("Empty query parameter: endpoint")
  }
  result <- .ct_request(
    method = "GET",
    path = "/bioactivity/assay/search/by-endpoint/",
    path_params = base::list(),
    query = base::list("endpoint" = params[["endpoint"]]),
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
