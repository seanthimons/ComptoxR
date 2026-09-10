#' Estimate a cationic dye
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' epi_ecosar_dye()
#' }
# Generated with specmill; do not edit by hand.
epi_ecosar_dye <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "ecosar/dye",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "epi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result <- run_hook("epi_ecosar_dye", "post_response", list(result = result, params = params))
  result
}
