#' Get predicted fate summary by DTXSID and property
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid
#' @param propName propName
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_fate_predicted_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_fate_predicted_search <- function(dtxsid, propName) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  if (base::is.null(propName)) {
    base::stop("Required input: propName")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid, "propName" = propName),
    list(dtxsid = list(type = "string"), propName = list(type = "string")),
    .api_validation$body_value,
    c(dtxsid = "query", propName = "query")
  )
  params <- base::list("dtxsid" = dtxsid, "propName" = propName)
  if (base::is.character(params[["dtxsid"]]) && base::any(!base::nzchar(params[["dtxsid"]]))) {
    base::stop("Empty query parameter: dtxsid")
  }
  if (base::is.character(params[["propName"]]) && base::any(!base::nzchar(params[["propName"]]))) {
    base::stop("Empty query parameter: propName")
  }
  result <- .ct_request(
    method = "GET",
    path = "/chemical/fate/summary/predicted/search/",
    path_params = base::list(),
    query = base::list("dtxsid" = params[["dtxsid"]], "propName" = params[["propName"]]),
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
