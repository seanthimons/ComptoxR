#' Stdizer Operations
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_operations()
#' }
# Generated with specmill; do not edit by hand.
chemi_stdizer_operations <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "stdizer/operations",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
