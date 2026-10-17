#' Get AOP data by Key Event
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param eventNumber eventNumber Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_search_by_event_number(eventNumber = 18L)
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_aop_search_by_event_number <- function(eventNumber) {
  eventNumber <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(eventNumber)
  if (base::is.null(eventNumber)) {
    base::stop("Required input: eventNumber")
  }
  .api_validation$parameter_values(
    base::list("eventNumber" = eventNumber),
    list(eventNumber = list(type = "array", items = list(format = "int32", type = "integer"))),
    .api_validation$body_value,
    c(eventNumber = "path")
  )
  params <- base::list("eventNumber" = eventNumber)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/aop/search/by-event-number/{eventNumber}",
      path_params = base::list("eventNumber" = params[["eventNumber"]]),
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
      params["eventNumber"] <- base::list(chunk)
      send(params)
    },
    params[["eventNumber"]],
    1L,
    on_error = "drop"
  )
}
