#' Get DTXSIDs by list
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param list Primary query parameter. Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_search_by_listname(list = "40CFR1164")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_chemicals_search_by_listname <- function(list) {
  params <- base::list("list" = list)
  result <- generic_request(
    "query" = params[["list"]],
    "endpoint" = "chemical/list/chemicals/search/by-listname/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
