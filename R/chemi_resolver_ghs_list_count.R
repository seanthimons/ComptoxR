#' Resolver Ghs List Count
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_ghs_list_count()
#' }
# Generated with apipak; do not edit by hand.
chemi_resolver_ghs_list_count <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "resolver/ghs-list-count",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
