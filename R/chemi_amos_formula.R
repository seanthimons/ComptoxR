#' Returns a list of substances that have the given molecular formula.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param formula Molecular furmula to search by.  Formula should be in Hill form.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_formula(formula = "DTXSID7020182")
#' }
chemi_amos_formula <- function(formula) {
  result <- generic_request(
    query = formula,
    endpoint = "amos/formula_search/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


