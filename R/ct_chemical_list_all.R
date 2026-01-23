#' Get all lists
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
#' ct_chemical_list_all(projection = "chemicallistall")
#' }
ct_chemical_list_all <- function(projection = "chemicallistall") {
  result <- generic_request(
    endpoint = "chemical/list/all",
    method = "GET",
    batch_limit = 0,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


