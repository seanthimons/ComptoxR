#' Services Preflight
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
#' chemi_services_preflight(query = "DTXSID7020182")
#' }
chemi_services_preflight <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "services/preflight",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


