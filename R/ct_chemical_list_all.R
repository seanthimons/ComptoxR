#' Get all lists
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param projection Projection options for chemical List APIs . Options: chemicallistall, chemicallistwithdtxsids, chemicallistname, ccdchemicaldetaillists (default: chemicallistall)
#' @param return_dtxsid Return all DTXSIDs contained within each list
#' @param coerce Coerce DTXSID strings per list to list-column (requires return_dtxsid = TRUE)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_all(projection = "chemicallistall")
#' }
ct_chemical_list_all <- function(projection = "chemicallistall", return_dtxsid = FALSE, coerce = FALSE) {
  result <- generic_request(
    endpoint = "chemical/list/all",
    method = "GET",
    batch_limit = 0,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


