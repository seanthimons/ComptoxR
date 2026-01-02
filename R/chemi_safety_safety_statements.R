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
#' chemi_safety_safety_statements(query = "DTXSID7020182")
#' }
chemi_safety_safety_statements <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/safety/statements",
    server = "chemi_burl",
    auth = FALSE
  )
}

