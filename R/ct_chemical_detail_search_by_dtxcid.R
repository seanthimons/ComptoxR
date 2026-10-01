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
#' @param dtxcid DSSTox Compound Identifier. Type: string
#' @param projection Projection options for chemical details APIs . Options: chemicaldetailstandard, chemicalidentifier, chemicalstructure, ntatoolkit, ccdchemicaldetails, ccdassaydetails, chemicaldetailall, compact (default: chemicaldetailall)
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_detail_search_by_dtxcid(dtxcid = "DTXCID505")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_detail_search_by_dtxcid <- function(dtxcid, projection = "chemicaldetailall") {
  params <- base::list("dtxcid" = dtxcid, "projection" = projection)
  result <- generic_request(
    "query" = params[["dtxcid"]],
    "endpoint" = "chemical/detail/search/by-dtxcid/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
