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
#' chemi_safety_safety_rqcodes(query = "DTXSID7020182")
#' }
chemi_safety_safety_rqcodes <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/safety/rqcodes",
    server = "chemi_burl",
    auth = FALSE
  )
}

