#' Get functional use categories
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_functional_use_category()
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_functional_use_category <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/exposure/functional-use/category",
    path_params = base::list(),
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
