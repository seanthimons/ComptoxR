#' Resolver Getannotationslist
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
#' chemi_resolver_getannotationslist(name = "DTXSID7020182")
#' }
chemi_resolver_getannotationslist <- function(name) {
  generic_request(
    endpoint = "resolver/getannotationslist",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    name = name
  )
}


