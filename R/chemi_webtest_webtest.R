#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_webtest(query = "DTXSID7020182")
#' }
chemi_webtest_webtest <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/webtest",
    server = "chemi_burl",
    auth = FALSE
  )
}

