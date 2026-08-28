#' Estimate an anionic surfactant
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_ecosar_surfactant_anionic()
#' }
epi_ecosar_surfactant_anionic <- function() {
  result <- generic_request(
    endpoint = "ecosar/surfactant/anionic",
    method = "GET",
    batch_limit = 0,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


