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
#' chemi_alerts_alerts_metadata(query = "DTXSID7020182")
#' }
chemi_alerts_alerts_metadata <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/alerts/metadata",
    server = "chemi_burl",
    auth = FALSE
  )
}

