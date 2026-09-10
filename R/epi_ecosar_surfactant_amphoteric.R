#' Estimate an amphoteric surfactant
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' epi_ecosar_surfactant_amphoteric()
#' }
# Generated with specmill; do not edit by hand.
epi_ecosar_surfactant_amphoteric <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "ecosar/surfactant/amphoteric",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "epi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
