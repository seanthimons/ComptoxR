#' Get observations by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxref_observations_search(dtxsid = "DTXSID1037806")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxref_observations_search <- function(dtxsid) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid),
    list(dtxsid = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(dtxsid = "path")
  )
  params <- base::list("dtxsid" = dtxsid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/hazard/toxref/observations/search/by-dtxsid/{dtxsid}",
      path_params = base::list("dtxsid" = params[["dtxsid"]]),
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
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    1L,
    on_error = "drop"
  )
}
