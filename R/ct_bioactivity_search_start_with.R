#' Search by starting value
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param value value Accepts a vector: one request is sent per element and the results are combined.
#' @param top top
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_search_start_with(value = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_search_start_with <- function(value, top = 500L) {
  value <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(value)
  if (base::is.null(value)) {
    base::stop("Required input: value")
  }
  .api_validation$parameter_values(
    base::list("value" = value, "top" = top),
    list(
      value = list(type = "array", items = list(type = "string")),
      top = list(default = 500L, format = "int32", type = "integer")
    ),
    .api_validation$body_value,
    c(value = "path", top = "query")
  )
  params <- base::list("value" = value, "top" = top)
  if (base::is.character(params[["top"]]) && base::any(!base::nzchar(params[["top"]]))) {
    base::stop("Empty query parameter: top")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/search/start-with/{value}",
      path_params = base::list("value" = params[["value"]]),
      query = base::list("top" = params[["top"]]),
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
      params["value"] <- base::list(chunk)
      send(params)
    },
    params[["value"]],
    1L,
    on_error = "drop"
  )
}
