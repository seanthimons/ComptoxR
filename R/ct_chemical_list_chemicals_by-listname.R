#' Get DTXSIDs by list
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_by_listname(query = "DTXSID7020182")
#' }
ct_chemical_list_chemicals_by_listname <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/list/chemicals/search/by-listname/",
    method = "GET",
		batch_limit = 1
  )
}

