#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param format Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_download_mol(query = "DTXSID7020182")
#' }
chemi_search_download_mol <- function(query, format = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(format)) options$format <- format

  generic_chemi_request(
    query = query,
    endpoint = "api/search/download/mol",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}