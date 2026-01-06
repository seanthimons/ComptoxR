#' Get chemical count by MS-ready formula
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param formula Chemical formula
#' @param projection Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_count_by_msready_formula(formula = "C15H16O2")
#' }
ct_chemical_count_by_msready_formula <- function(formula, projection = NULL) {
  generic_request(
    query = formula,
    endpoint = "chemical/count/by-msready-formula/",
    method = "GET",
    batch_limit = 1,
    projection = projection
  )
}

