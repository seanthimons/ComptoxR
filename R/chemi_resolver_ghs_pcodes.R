#' Resolver Ghs Pcodes
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_ghs_pcodes()
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_ghs_pcodes <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "resolver/ghs/pcodes",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
