#' Estimate an anionic polymer
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
#' epi_ecosar_polymer_anionic()
#' }
epi_ecosar_polymer_anionic <- function() {
  result <- generic_request(
    endpoint = "ecosar/polymer/anionic",
    method = "GET",
    batch_limit = 0,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


