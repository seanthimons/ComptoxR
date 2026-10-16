#' Get chemical count by exact formula
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param formula formula Accepts a vector: one request is sent per element and the results are combined.
#' @param projection projection
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_count_by_exact_formula(formula = "C15H16O2")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_count_by_exact_formula <- function(formula, projection = "count") {
  if (base::is.null(formula)) {
    base::stop("Required input: formula")
  }
  .api_validation$parameter_values(
    base::list("formula" = formula, "projection" = projection),
    list(
      formula = list(type = "array", items = list(type = "string")),
      projection = list(default = "count", type = "string")
    ),
    .api_validation$body_value,
    c(formula = "path", projection = "query")
  )
  params <- base::list("formula" = formula, "projection" = projection)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/count/by-exact-formula/{formula}",
      path_params = base::list("formula" = params[["formula"]]),
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
