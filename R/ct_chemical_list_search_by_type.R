#' Get lists by list type
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param type Chemical List Type. Type: string
#' @param projection Projection options for chemical List APIs . Options: chemicallistall, chemicallistwithdtxsids, chemicallistname, ccdchemicaldetaillists (default: chemicallistall)
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_search_by_type(type = "other")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_search_by_type <- function(type, projection = "chemicallistall") {
  params <- base::list("type" = type, "projection" = projection)
  result <- generic_request(
    "query" = params[["type"]],
    "endpoint" = "chemical/list/search/by-type/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
