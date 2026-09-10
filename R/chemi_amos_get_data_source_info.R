#' Returns a list of major data sources in AMOS with some supplemental information.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_data_source_info()
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_data_source_info <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "amos/get_data_source_info/",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
