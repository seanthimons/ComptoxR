#' Get lists by name
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param listName Chemical List Name. Type: string
#' @param projection Projection options for chemical List APIs . Options: chemicallistall, chemicallistwithdtxsids, chemicallistname, ccdchemicaldetaillists (default: chemicallistall)
#' @param extract_dtxsids Extract DTXSIDs from results into character vector (requires projection = 'chemicallistwithdtxsids')
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_search_by_name(listName = "40CFR1164")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_search_by_name <- function(listName, projection = "chemicallistall", extract_dtxsids = FALSE) {
  params <- base::list("listName" = listName, "projection" = projection, "extract_dtxsids" = extract_dtxsids)
  result <- generic_request(
    "query" = params[["listName"]],
    "endpoint" = "chemical/list/search/by-name/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result <- run_hook("ct_chemical_list_search_by_name", "post_response", base::list(result = result, params = params))
  result
}
