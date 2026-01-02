#' Retrieve previously generated report by response ID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param endpoint Optional parameter
#' @param method Optional parameter
#' @param format Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_webtest_report(query = "DTXSID7020182")
#' }
chemi_webtest_webtest_report <- function(query, endpoint = NULL, method = NULL, format = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(endpoint)) options$endpoint <- endpoint
  if (!is.null(method)) options$method <- method
  if (!is.null(format)) options$format <- format

  generic_chemi_request(
    query = query,
    endpoint = "api/webtest/report",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}