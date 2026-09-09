#' Resolver Getallannotations
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_getallannotations()
#' }
# Generated with apipak; do not edit by hand.
chemi_resolver_getallannotations <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "resolver/getallannotations",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
