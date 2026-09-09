#' Returns a list of all functional use classes that are assigned to at least one substance.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_list_functional_classes()
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_list_functional_classes <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "amos/list_functional_classes",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
