#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param page Optional parameter
#' @param itemsPerPage Optional parameter
#' @param search Optional parameter
#' @param linkBy Optional parameter
#' @param report Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolver_getpubchemlist(query = "DTXSID7020182")
#' }
chemi_resolver_resolver_getpubchemlist <- function(query, page = NULL, itemsPerPage = NULL, search = NULL, linkBy = NULL, report = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(page)) options$page <- page
  if (!is.null(itemsPerPage)) options$itemsPerPage <- itemsPerPage
  if (!is.null(search)) options$search <- search
  if (!is.null(linkBy)) options$linkBy <- linkBy
  if (!is.null(report)) options$report <- report

  generic_chemi_request(
    query = query,
    endpoint = "api/resolver/getpubchemlist",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}