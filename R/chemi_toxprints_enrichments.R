#' Toxprints Enrichments
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_enrichments()
#' }
# Generated with apipak; do not edit by hand.
chemi_toxprints_enrichments <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "toxprints/enrichments",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
