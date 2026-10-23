#' Get mol file by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid dtxsid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of mol file strings, one per identifier
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_file_mol_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_file_mol_search <- function(dtxsid) {
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
    base::list("dtxsid" = dtxsid),
    list(dtxsid = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(dtxsid = "path")
  )
  params <- base::list("dtxsid" = dtxsid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/file/mol/search/by-dtxsid/{dtxsid}",
      path_params = base::list("dtxsid" = params[["dtxsid"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_file",
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
