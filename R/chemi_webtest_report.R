#' Retrieve previously generated report by response ID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param structure Required parameter
#' @param endpoint Required parameter
#' @param method Optional parameter (default: consensus)
#' @param format Optional parameter. Options: JSON, HTML, PDF (default: HTML)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_report(structure = "DTXSID7020182")
#' }
chemi_webtest_report <- function(structure, endpoint, method = "consensus", format = "HTML") {
  # Collect optional parameters
  options <- list()
  if (!is.null(structure)) options[['structure']] <- structure
  if (!is.null(endpoint)) options[['endpoint']] <- endpoint
  if (!is.null(method)) options[['method']] <- method
  if (!is.null(format)) options[['format']] <- format
    result <- generic_request(
    query = NULL,
    endpoint = "webtest/report",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


