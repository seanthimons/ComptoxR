#' Services Caspreflight
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
#' chemi_services_caspreflight(query = "DTXSID7020182")
#' }
chemi_services_caspreflight <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "services/caspreflight",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


