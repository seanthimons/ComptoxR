#' Get predicted properties by property and range
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param propertyId propertyId Accepts a vector: one request is sent per element and the results are combined.
#' @param start start
#' @param end end
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted_search_by_range(propertyId = "1", start = 0, end = 100)
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_property_predicted_search_by_range <- function(propertyId, start, end) {
  propertyId <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(propertyId)
  if (base::is.null(propertyId)) {
    base::stop("Required input: propertyId")
  }
  if (base::is.null(start)) {
    base::stop("Required input: start")
  }
  if (base::is.null(end)) {
    base::stop("Required input: end")
  }
  .api_validation$parameter_values(
    base::list("propertyId" = propertyId, "start" = start, "end" = end),
    list(
      propertyId = list(type = "array", items = list(type = "string")),
      start = list(format = "double", type = "number"),
      end = list(format = "double", type = "number")
    ),
    .api_validation$body_value,
    c(propertyId = "path", start = "path", end = "path")
  )
  params <- base::list("propertyId" = propertyId, "start" = start, "end" = end)
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/chemical/property/predicted/search/by-range/{propertyId}/{start}/{end}",
      "path_params" = base::list(
        "propertyId" = params[["propertyId"]],
        "start" = params[["start"]],
        "end" = params[["end"]]
      ),
      "query" = list(),
      "body" = NULL,
      "response_policy" = function(response, context, decode) {
        context$query <- params[["propertyId"]]
        .ct_tidy(response, context, decode)
      },
      "server" = list(url = "https://comptox.epa.gov/ctx-api"),
      "server_resolver" = list(name = ".ct_server_url", key = "ctx_burl"),
      "auth" = list(list(list(
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
      params["propertyId"] <- base::list(chunk)
      send(params)
    },
    params[["propertyId"]],
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
