#' Get chemicals by exact formula
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param formula Chemical formula
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_by_exact_formula(formula = "C15H16O2")
#' }
ct_chemical_by_exact_formula <- function(formula) {
  generic_request(
    query = formula,
    endpoint = "chemical/search/by-exact-formula/",
    method = "GET",
    batch_limit = 1
  )
}

