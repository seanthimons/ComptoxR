#' Get chemicals by exact formula
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
#' ct_chemical_search_by_exact_formula(formula = "C15H16O2")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_search_by_exact_formula <- function(formula) {
  params <- list("formula" = formula)
  result <- generic_request(
    "query" = params[["formula"]],
    "endpoint" = "chemical/search/by-exact-formula/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
