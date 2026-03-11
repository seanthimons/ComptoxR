#' Get lists by name
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param listName Chemical List Name. Type: string
#' @param projection Projection options for chemical List APIs . Options: chemicallistall, chemicallistwithdtxsids, chemicallistname, ccdchemicaldetaillists (default: chemicallistall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_by_name(listName = "40CFR1164")
#' }
ct_chemical_list_by_name <- function(listName, projection = "chemicallistall") {
  result <- generic_request(
    query = listName,
    endpoint = "chemical/list/search/by-name/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


