#' Get experimental properties by property and range
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param propertyName propertyName Accepts a vector: one request is sent per element and the results are combined.
#' @param start start
#' @param end end
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_property_experimental_search_by_range(propertyName = "Melting Point", start = 0, end = 100)
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_property_experimental_search_by_range <- function(propertyName, start, end) {
  if (base::is.null(propertyName)) {
    base::stop("Required input: propertyName")
  }
  if (base::is.null(start)) {
    base::stop("Required input: start")
  }
  if (base::is.null(end)) {
    base::stop("Required input: end")
  }
  .api_validation$parameter_values(
    base::list("propertyName" = propertyName, "start" = start, "end" = end),
    list(
      propertyName = list(type = "array", items = list(type = "string")),
      start = list(format = "double", type = "number"),
      end = list(format = "double", type = "number")
    ),
    .api_validation$body_value,
    c(propertyName = "path", start = "path", end = "path")
  )
  params <- base::list("propertyName" = propertyName, "start" = start, "end" = end)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/property/experimental/search/by-range/{propertyName}/{start}/{end}",
      path_params = base::list(
        "propertyName" = params[["propertyName"]],
        "start" = params[["start"]],
        "end" = params[["end"]]
      ),
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
      params["propertyName"] <- base::list(chunk)
      send(params)
    },
    params[["propertyName"]],
    1L,
    on_error = "drop"
  )
}
