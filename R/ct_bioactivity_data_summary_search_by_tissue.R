#' Get summary data by DTXSID and assay tissue origin
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid
#' @param tissue tissue
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_summary_search_by_tissue(dtxsid = "DTXSID7024241")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_summary_search_by_tissue <- function(dtxsid, tissue) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  if (base::is.null(tissue)) {
    base::stop("Required input: tissue")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid, "tissue" = tissue),
    list(dtxsid = list(type = "string"), tissue = list(type = "string")),
    .api_validation$body_value,
    c(dtxsid = "query", tissue = "query")
  )
  params <- base::list("dtxsid" = dtxsid, "tissue" = tissue)
  if (base::is.character(params[["dtxsid"]]) && base::any(!base::nzchar(params[["dtxsid"]]))) {
    base::stop("Empty query parameter: dtxsid")
  }
  if (base::is.character(params[["tissue"]]) && base::any(!base::nzchar(params[["tissue"]]))) {
    base::stop("Empty query parameter: tissue")
  }
  result <- .ct_request(
    method = "GET",
    path = "/bioactivity/data/summary/search/by-tissue/",
    path_params = base::list(),
    query = base::list("dtxsid" = params[["dtxsid"]], "tissue" = params[["tissue"]]),
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
