#' Services Release Notes
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_services_release_notes()
#' }
# Generated with specmill; do not edit by hand.
chemi_services_release_notes <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "services/release_notes",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
