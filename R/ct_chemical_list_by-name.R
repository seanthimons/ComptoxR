#' Get lists by name
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param projection Projection options for chemical List APIs . Options: chemicallistall, chemicallistwithdtxsids, chemicallistname, ccdchemicaldetaillists (default: chemicallistall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_by_name(listName = "DTXSID7020182")
#' }
ct_chemical_list_by_name <- function(projection = "chemicallistall") {
  result <- generic_request(
    endpoint = "chemical/list/search/by-name/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


