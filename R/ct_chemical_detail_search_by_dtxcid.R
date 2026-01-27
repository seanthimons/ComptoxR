#' Get data for a batch of DTXCIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_detail_search_by_dtxcid_bulk(query = c("DTXSID9064922", "DTXSID20582510", "DTXSID801027235"))
#' }
ct_chemical_detail_search_by_dtxcid_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-dtxcid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get data by DTXCID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxcid DSSTox Compound Identifier. Type: string
#' @param projection Projection options for chemical details APIs . Options: chemicaldetailstandard, chemicalidentifier, chemicalstructure, ntatoolkit, ccdchemicaldetails, ccdassaydetails, chemicaldetailall, compact (default: chemicaldetailall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_detail_search_by_dtxcid(dtxcid = "DTXCID505")
#' }
ct_chemical_detail_search_by_dtxcid <- function(dtxcid, projection = "chemicaldetailall") {
  result <- generic_request(
    query = dtxcid,
    endpoint = "chemical/detail/search/by-dtxcid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


