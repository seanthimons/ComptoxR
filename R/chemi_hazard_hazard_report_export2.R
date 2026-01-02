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
#' chemi_hazard_hazard_report_export2(query = "DTXSID7020182")
#' }
chemi_hazard_hazard_report_export2 <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/hazard/report/export2",
    server = "chemi_burl",
    auth = FALSE
  )
}

