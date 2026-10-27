#' Get MS-ready chemicals by DTXCID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxcid dtxcid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_dtxcid(dtxcid = "DTXCID30182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_msready_search_by_dtxcid <- function(dtxcid) {
  dtxcid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(dtxcid)
  if (base::is.null(dtxcid)) {
    base::stop("Required input: dtxcid")
  }
  .api_validation$parameter_values(
    base::list("dtxcid" = dtxcid),
    list(dtxcid = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(dtxcid = "path")
  )
  params <- base::list("dtxcid" = dtxcid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/msready/search/by-dtxcid/{dtxcid}",
      path_params = base::list("dtxcid" = params[["dtxcid"]]),
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
      params["dtxcid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxcid"]],
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
