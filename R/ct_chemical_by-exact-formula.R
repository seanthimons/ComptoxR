#' Get chemicals by exact formula
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
#' ct_chemical_by_exact_formula(query = "DTXSID7020182")
#' }
ct_chemical_by_exact_formula <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/search/by-exact-formula/",
    method = "GET",
		batch_limit = 1
  )
}

