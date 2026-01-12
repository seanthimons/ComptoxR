#' Services Universalpreflight
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
#' chemi_services_universalpreflight(query = "DTXSID7020182")
#' }
chemi_services_universalpreflight <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "services/universalpreflight",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


