#' Get lists containing DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid Accepts a vector: one request is sent per element and the results are combined.
#' @param projection Projection options for chemical List APIs
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_search(dtxsid = "DTXSID1020560")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_search <- function(dtxsid, projection = "chemicallistall") {
  dtxsid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(dtxsid)
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid, "projection" = projection),
    list(
      dtxsid = list(type = "array", items = list(type = "string")),
      projection = list(
        description = "Projection options for chemical List APIs ",
        enum = list("chemicallistall", "chemicallistwithdtxsids", "chemicallistname", "ccdchemicaldetaillists"),
        type = "string",
        default = "chemicallistall"
      )
    ),
    .api_validation$body_value,
    c(dtxsid = "path", projection = "query")
  )
  params <- base::list("dtxsid" = dtxsid, "projection" = projection)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/list/search/by-dtxsid/{dtxsid}",
      path_params = base::list("dtxsid" = params[["dtxsid"]]),
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
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
