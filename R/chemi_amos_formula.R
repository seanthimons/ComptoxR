#' Returns a list of substances that have the given molecular formula.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_formula()
#' }
chemi_amos_formula <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/formula_search/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


