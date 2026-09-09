#' Get MS-ready chemicals by formula
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param formula Chemical formula. Type: string
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_formula(formula = "C16H24N2O5S")
#' }
# Generated with apipak; do not edit by hand.
ct_chemical_msready_search_by_formula <- function(formula) {
  params <- list("formula" = formula)
  result <- generic_request(
    "query" = params[["formula"]],
    "endpoint" = "chemical/msready/search/by-formula/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
