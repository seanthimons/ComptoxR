#' Stdizer Operations
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_operations()
#' }
chemi_stdizer_operations <- function() {
  generic_request(
    query = NULL,
    endpoint = "stdizer/operations",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


