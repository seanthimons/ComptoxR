#' Get data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @param query Character vector of strings to send in request body
#' @param projection Projection options for chemical details APIs . Options: chemicaldetailstandard, chemicalidentifier, chemicalstructure, ntatoolkit, ccdchemicaldetails, ccdassaydetails, chemicaldetailall, compact (default: chemicaldetailall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_detail_search_bulk(query = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
ct_chemical_detail_search_bulk <- function(query, projection = "chemicaldetailall") {
  result <- generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100")),
    `projection` = projection
  )

  return(result)
}
