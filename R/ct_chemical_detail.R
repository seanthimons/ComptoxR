#' Get data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param projection Projection options for chemical details APIs . Options: chemicaldetailstandard, chemicalidentifier, chemicalstructure, ntatoolkit, ccdchemicaldetails, ccdassaydetails, chemicaldetailall, compact (default: chemicaldetailall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_detail(projection = "chemicaldetailall")
#' }
ct_chemical_detail <- function(projection = "chemicaldetailall") {
  result <- generic_request(
    endpoint = "chemical/detail/search/by-dtxsid/",
    method = "POST",
    batch_limit = 0,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


