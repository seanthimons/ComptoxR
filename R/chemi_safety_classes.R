#' Safety Classes
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_safety_classes()
#' }
chemi_safety_classes <- function() {
  generic_request(
    query = NULL,
    endpoint = "safety/classes",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


