#' Get chemicals for a batch of  MS-ready formulas
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_search_by_msready_formula_bulk()
#' }
ct_chemical_search_by_msready_formula_bulk <- function() {
  # Build request body
  body <- list()

  result <- generic_request(
    query = NULL,
    endpoint = "chemical/search/by-msready-formula/",
    method = "POST",
    batch_limit = NULL,
    body = body
  )

  # Additional post-processing can be added here

  return(result)
}


#' Get chemicals by MS-ready formula
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
#' ct_chemical_search_by_msready_formula(formula = "C15H16O2")
#' }
ct_chemical_search_by_msready_formula <- function(formula) {
  result <- generic_request(
    query = formula,
    endpoint = "chemical/search/by-msready-formula/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


