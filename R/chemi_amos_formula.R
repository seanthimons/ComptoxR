#' Returns a list of substances that have the given molecular formula.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param formula Molecular formula to search by.  Formula should be in Hill form.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_formula(formula = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_formula <- function(formula) {
  params <- list("formula" = formula)
  result <- generic_request(
    "query" = params[["formula"]],
    "endpoint" = "amos/formula_search/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
