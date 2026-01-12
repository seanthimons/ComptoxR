#' Toxprints Enrichments
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_enrichments()
#' }
chemi_toxprints_enrichments <- function() {
  generic_request(
    query = NULL,
    endpoint = "toxprints/enrichments",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


