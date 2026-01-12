#' Safety Statements
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_safety_statements()
#' }
chemi_safety_statements <- function() {
  generic_request(
    query = NULL,
    endpoint = "safety/statements",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


