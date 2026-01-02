#' Get all list types
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
#' ct_chemical_list_type(query = "DTXSID7020182")
#' }
ct_chemical_list_type <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/list/type",
    method = "GET",
		batch_limit = 1
  )
}

