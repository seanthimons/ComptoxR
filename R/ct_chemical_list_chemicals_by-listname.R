#' Get DTXSIDs by list
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param list Primary query parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_by_listname(list = "40CFR1164")
#' }
ct_chemical_list_chemicals_by_listname <- function(list) {
  generic_request(
    query = list,
    endpoint = "chemical/list/chemicals/search/by-listname/",
    method = "GET",
    batch_limit = 1
  )
}

