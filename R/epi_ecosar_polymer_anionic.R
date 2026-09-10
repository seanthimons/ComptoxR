#' Estimate an anionic polymer
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' epi_ecosar_polymer_anionic()
#' }
# Generated with specmill; do not edit by hand.
epi_ecosar_polymer_anionic <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "ecosar/polymer/anionic",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "epi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
