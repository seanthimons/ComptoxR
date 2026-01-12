#' Retrieves a list of methods in the database with their supplemental information.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_method_list()
#' }
chemi_amos_method_list <- function() {
  generic_request(
    query = NULL,
    endpoint = "amos/method_list",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


