#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param id Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_hazard_hazard_reports_export(query = "DTXSID7020182")
#' }
chemi_hazard_hazard_reports_export <- function(query, id = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(id)) options$id <- id

  generic_chemi_request(
    query = query,
    endpoint = "api/hazard/reports/export",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}