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
#' chemi_resolver_resolver_getdatasources(query = "DTXSID7020182")
#' }
chemi_resolver_resolver_getdatasources <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/resolver/getdatasources",
    server = "chemi_burl",
    auth = FALSE
  )
}

