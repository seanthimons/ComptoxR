#' Get DTXSIDs by list
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param list list Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_search_by_listname(list = "40CFR1164")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_chemicals_search_by_listname <- function(list) {
  list <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(list)
  if (base::is.null(list)) {
    base::stop("Required input: list")
  }
  .api_validation$parameter_values(
    base::list("list" = list),
    list(list = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(list = "path")
  )
  params <- base::list("list" = list)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/list/chemicals/search/by-listname/{list}",
      path_params = base::list("list" = params[["list"]]),
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
      params["list"] <- base::list(chunk)
      send(params)
    },
    params[["list"]],
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
