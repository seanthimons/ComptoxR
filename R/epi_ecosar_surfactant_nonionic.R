#' Estimate a nonionic surfactant
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' epi_ecosar_surfactant_nonionic()
#' }
# Generated with apipak; do not edit by hand.
epi_ecosar_surfactant_nonionic <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "ecosar/surfactant/nonionic",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "epi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result <- run_hook("epi_ecosar_surfactant_nonionic", "post_response", list(result = result, params = params))
  result
}
