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
#' chemi_hazard_hazard_download(query = "DTXSID7020182")
#' }
chemi_hazard_hazard_download <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/hazard/download",
    server = "chemi_burl",
    auth = FALSE
  )
}

