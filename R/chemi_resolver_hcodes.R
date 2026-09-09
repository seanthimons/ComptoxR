#' Resolver Hcodes
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_hcodes()
#' }
# Generated with apipak; do not edit by hand.
chemi_resolver_hcodes <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "resolver/hcodes",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
