#' Get chemicals by exact formula
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param formula Chemical formula. Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_by_exact_formula(formula = "C15H16O2")
#' }
ct_chemical_by_exact_formula <- function(formula) {
  result <- generic_request(
    query = formula,
    endpoint = "chemical/search/by-exact-formula/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


