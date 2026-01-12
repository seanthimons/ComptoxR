#' Resolver Getannotation
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Required parameter
#' @param heading Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getannotation(name = "DTXSID7020182")
#' }
chemi_resolver_getannotation <- function(name, heading) {
  generic_request(
    endpoint = "resolver/getannotation",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    name = name,
    heading = heading
  )
}


