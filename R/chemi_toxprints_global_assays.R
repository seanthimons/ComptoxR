#' Toxprints Global Assays
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
#' chemi_toxprints_global_assays(category = "DTXSID7020182")
#' }
chemi_toxprints_global_assays <- function(category, label = NULL) {
  generic_request(
    endpoint = "toxprints/global_assays",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    category = category,
    label = label
  )
}


