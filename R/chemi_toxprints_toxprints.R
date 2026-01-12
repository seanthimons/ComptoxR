#' Toxprints Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param category Required parameter
#' @param label Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_toxprints(category = "DTXSID7020182")
#' }
chemi_toxprints_toxprints <- function(category, label = NULL) {
  generic_request(
    endpoint = "toxprints/toxprints",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    category = category,
    label = label
  )
}


