#' Get lists by list type
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param type type Accepts a vector: one request is sent per element and the results are combined.
#' @param projection Projection options for chemical List APIs
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_search_by_type(type = "other")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_search_by_type <- function(type, projection = "chemicallistall") {
  if (base::is.null(type)) {
    base::stop("Required input: type")
  }
  .api_validation$parameter_values(
    base::list("type" = type, "projection" = projection),
    list(
      type = list(type = "array", items = list(type = "string")),
      projection = list(
        description = "Projection options for chemical List APIs ",
        enum = list("chemicallistall", "chemicallistwithdtxsids", "chemicallistname", "ccdchemicaldetaillists"),
        type = "string",
        default = "chemicallistall"
      )
    ),
    .api_validation$body_value,
    c(type = "path", projection = "query")
  )
  params <- base::list("type" = type, "projection" = projection)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/list/search/by-type/{type}",
      path_params = base::list("type" = params[["type"]]),
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
      params["type"] <- base::list(chunk)
      send(params)
    },
    params[["type"]],
    1L,
    on_error = "drop"
  )
}
