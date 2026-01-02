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
#' chemi_services_services_convert(query = "DTXSID7020182")
#' }
chemi_services_services_convert <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/services/convert",
    server = "chemi_burl",
    auth = FALSE
  )
}

