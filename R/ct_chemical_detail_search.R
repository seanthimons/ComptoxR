#' Get data for a batch of DTXSIDs
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
#' ct_chemical_detail_search_bulk(query = c("DTXSID5044946", "DTXSID1023786", "DTXSID7043792"))
#' }
ct_chemical_detail_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Projection options for chemical details APIs . Options: chemicaldetailstandard, chemicalidentifier, chemicalstructure, ntatoolkit, ccdchemicaldetails, ccdassaydetails, chemicaldetailall, compact (default: chemicaldetailall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_detail_search(dtxsid = "DTXSID7020182")
#' }
ct_chemical_detail_search <- function(dtxsid, projection = "chemicaldetailall") {
  result <- generic_request(
    query = dtxsid,
    endpoint = "chemical/detail/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


