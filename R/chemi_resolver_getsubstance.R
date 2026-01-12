#' Resolver Getsubstance
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
#' chemi_resolver_getsubstance(name = "DTXSID7020182")
#' }
chemi_resolver_getsubstance <- function(name) {
  generic_request(
    endpoint = "resolver/getsubstance",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    name = name
  )
}


