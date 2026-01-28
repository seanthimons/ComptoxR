#' Get chemical count by MS-ready formula
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param formula Chemical formula. Type: string
#' @param projection Optional parameter (default: count)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_count_by_msready_formula(formula = "C15H16O2")
#' }
ct_chemical_count_by_msready_formula <- function(formula, projection = "count") {
  result <- generic_request(
    query = formula,
    endpoint = "chemical/count/by-msready-formula/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


