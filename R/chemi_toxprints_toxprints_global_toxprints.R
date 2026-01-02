#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param label Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_toxprints_global_toxprints(query = "DTXSID7020182")
#' }
chemi_toxprints_toxprints_global_toxprints <- function(query, label = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(label)) options$label <- label

  generic_chemi_request(
    query = query,
    endpoint = "api/toxprints/global_toxprints",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}