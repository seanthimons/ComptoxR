#' Returns a list of release notes for AMOS.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_release_notes()
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_release_notes <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "amos/release_notes",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
