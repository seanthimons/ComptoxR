#' Get MS-ready chemicals by formula
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
#' ct_chemical_msready_search_by_formula(formula = "C16H24N2O5S")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_msready_search_by_formula <- function(formula) {
  formula <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(formula)
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
      path = "/chemical/msready/search/by-formula/{formula}",
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
