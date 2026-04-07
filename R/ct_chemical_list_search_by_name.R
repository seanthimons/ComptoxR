#' Get lists by name
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param listName Chemical List Name. Type: string
#' @param projection Projection options for chemical List APIs . Options: chemicallistall, chemicallistwithdtxsids, chemicallistname, ccdchemicaldetaillists (default: chemicallistall)
#' @param extract_dtxsids Extract DTXSIDs from results into character vector (requires projection = 'chemicallistwithdtxsids')
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_search_by_name(listName = "40CFR1164")
#' }
ct_chemical_list_search_by_name <- function(listName, projection = "chemicallistall", extract_dtxsids = FALSE) {
  result <- generic_request(
    query = listName,
    endpoint = "chemical/list/search/by-name/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

    result <- run_hook("ct_chemical_list_search_by_name", "post_response", list(result = result, params = list(extract_dtxsids = extract_dtxsids)))
# Additional post-processing can be added here

  return(result)
}


