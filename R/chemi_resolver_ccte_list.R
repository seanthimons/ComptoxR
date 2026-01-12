#' Resolver Ccte List
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_ccte_list(name = "DTXSID7020182")
#' }
chemi_resolver_ccte_list <- function(name) {
  generic_request(
    endpoint = "resolver/ccte-list",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    name = name
  )
}


