#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param search Optional parameter
#' @param linkBy Optional parameter
#' @param report Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolver_exportpubchemlist(query = "DTXSID7020182")
#' }
chemi_resolver_resolver_exportpubchemlist <- function(query, search = NULL, linkBy = NULL, report = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(search)) options$search <- search
  if (!is.null(linkBy)) options$linkBy <- linkBy
  if (!is.null(report)) options$report <- report

  generic_chemi_request(
    query = query,
    endpoint = "api/resolver/exportpubchemlist",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}