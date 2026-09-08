#' Returns a list of all functional use classes that are assigned to at least one substance.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_list_functional_classes()
#' }
chemi_amos_list_functional_classes <- function() {
  result <- generic_request(
    endpoint = "amos/list_functional_classes",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
