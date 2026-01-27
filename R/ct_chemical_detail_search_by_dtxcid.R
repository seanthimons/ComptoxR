#' Get data for a batch of DTXCIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_detail_search_by_dtxcid_bulk()
#' }
ct_chemical_detail_search_by_dtxcid_bulk <- function() {
  # Build request body
  body <- list()

  result <- generic_request(
    query = NULL,
    endpoint = "chemical/detail/search/by-dtxcid/",
    method = "POST",
    batch_limit = NULL,
    body = body
  )

  # Additional post-processing can be added here

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


