#' Get lists by list type
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param type Chemical List Type. Type: string
#' @param projection Projection options for chemical List APIs . Options: chemicallistall, chemicallistwithdtxsids, chemicallistname, ccdchemicaldetaillists (default: chemicallistall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_by_type(type = "other")
#' }
ct_chemical_list_by_type <- function(type, projection = "chemicallistall") {
  result <- generic_request(
    query = type,
    endpoint = "chemical/list/search/by-type/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


