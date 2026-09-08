#' Returns a list of DTXSIDs for the given functional use.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param functional_class Functional use class.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_functional_class(functional_class = "DTXSID7020182")
#' }
chemi_amos_functional_class <- function(functional_class) {
  result <- generic_request(
    query = functional_class,
    endpoint = "amos/functional_class_search/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
