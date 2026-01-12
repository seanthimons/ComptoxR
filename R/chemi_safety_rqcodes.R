#' Safety Rqcodes
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A list of DTXSIDs to search for
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_safety_rqcodes(query = "DTXSID7020182")
#' }
chemi_safety_rqcodes <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "safety/rqcodes",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


