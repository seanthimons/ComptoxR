#' Get all assay annotations
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param projection projection
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay(projection = "assay-all")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay <- function(projection = "assay-all") {
  .api_validation$parameter_values(
    base::list("projection" = projection),
    list(projection = list(default = "assay-all", type = "string")),
    .api_validation$body_value,
    c(projection = "query")
  )
  params <- base::list("projection" = projection)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  result <- .ct_request(
    method = "GET",
    path = "/bioactivity/assay/",
    path_params = base::list(),
    query = base::list("projection" = params[["projection"]]),
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
