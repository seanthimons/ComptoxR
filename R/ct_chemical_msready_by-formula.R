#' Get MS-ready chemicals by formula
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
#' ct_chemical_msready_by_formula(query = "DTXSID7020182")
#' }
ct_chemical_msready_by_formula <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/msready/search/by-formula/",
    method = "GET",
		batch_limit = 1
  )
}

