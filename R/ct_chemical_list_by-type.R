#' Get lists by list type
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param type Chemical List Type
#' @param projection Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_by_type(type = "other")
#' }
ct_chemical_list_by_type <- function(type, projection = NULL) {
  generic_request(
    query = type,
    endpoint = "chemical/list/search/by-type/",
    method = "GET",
    batch_limit = 1,
    projection = projection
  )
}

