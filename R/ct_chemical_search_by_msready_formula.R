#' Get chemicals for a batch of  MS-ready formulas
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of strings to send in request body
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_by_msready_formula_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_search_by_msready_formula_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "chemical/search/by-msready-formula/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get chemicals by MS-ready formula
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param formula formula Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_by_msready_formula(formula = "C15H16O2")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_search_by_msready_formula <- function(formula) {
  if (base::is.null(formula)) {
    base::stop("Required input: formula")
  }
  .api_validation$parameter_values(
    base::list("formula" = formula),
    list(formula = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(formula = "path")
  )
  params <- base::list("formula" = formula)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/search/by-msready-formula/{formula}",
      path_params = base::list("formula" = params[["formula"]]),
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
      params["formula"] <- base::list(chunk)
      send(params)
    },
    params[["formula"]],
    1L,
    on_error = "drop"
  )
}
