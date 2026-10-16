#' Get data for a batch of DTXCIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @param projection Projection options for chemical details APIs . Options: chemicaldetailstandard, chemicalidentifier, chemicalstructure, ntatoolkit, ccdchemicaldetails, ccdassaydetails, chemicaldetailall, compact (default: chemicaldetailall)
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_detail_search_by_dtxcid_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_detail_search_by_dtxcid_bulk <- function(query, projection = "chemicaldetailall") {
  params <- base::list("query" = query, "projection" = projection)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "chemical/detail/search/by-dtxcid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100")),
    "projection" = params[["projection"]]
  )
  result
}

#' Get data by DTXCID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxcid dtxcid Accepts a vector: one request is sent per element and the results are combined.
#' @param projection Projection options for chemical details APIs
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_detail_search_by_dtxcid(dtxcid = "DTXCID505")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_detail_search_by_dtxcid <- function(dtxcid, projection = "chemicaldetailall") {
  if (base::is.null(dtxcid)) {
    base::stop("Required input: dtxcid")
  }
  .api_validation$parameter_values(
    base::list("dtxcid" = dtxcid, "projection" = projection),
    list(
      dtxcid = list(type = "array", items = list(type = "string")),
      projection = list(
        description = "Projection options for chemical details APIs ",
        enum = list(
          "chemicaldetailstandard",
          "chemicalidentifier",
          "chemicalstructure",
          "ntatoolkit",
          "ccdchemicaldetails",
          "ccdassaydetails",
          "chemicaldetailall",
          "compact"
        ),
        type = "string",
        default = "chemicaldetailall"
      )
    ),
    .api_validation$body_value,
    c(dtxcid = "path", projection = "query")
  )
  params <- base::list("dtxcid" = dtxcid, "projection" = projection)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/detail/search/by-dtxcid/{dtxcid}",
      path_params = base::list("dtxcid" = params[["dtxcid"]]),
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
      params["dtxcid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxcid"]],
    1L,
    on_error = "drop"
  )
}
