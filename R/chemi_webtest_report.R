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
  generic_request(
    endpoint = "webtest/report",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    structure = structure,
    endpoint = endpoint,
    method = method,
    format = format
  )
}


