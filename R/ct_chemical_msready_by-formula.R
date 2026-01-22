#' Get MS-ready chemicals by formula
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
#' ct_chemical_msready_by_formula(formula = "C16H24N2O5S")
#' }
ct_chemical_msready_by_formula <- function(formula) {
  generic_request(
    query = formula,
    endpoint = "chemical/msready/search/by-formula/",
    method = "GET",
    batch_limit = 1
  )
}

