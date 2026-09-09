#' Get chemical count by MS-ready formula
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param formula Chemical formula. Type: string
#' @param projection Optional parameter (default: count)
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_count_by_msready_formula(formula = "C15H16O2")
#' }
# Generated with apipak; do not edit by hand.
ct_chemical_count_by_msready_formula <- function(formula, projection = "count") {
  params <- list("formula" = formula, "projection" = projection)
  result <- generic_request(
    "query" = params[["formula"]],
    "endpoint" = "chemical/count/by-msready-formula/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
