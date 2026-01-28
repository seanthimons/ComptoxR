#' Toxprints Enrichments
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_enrichments()
#' }
chemi_toxprints_enrichments <- function() {
  result <- generic_request(
    endpoint = "toxprints/enrichments",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


