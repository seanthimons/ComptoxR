#' Resolver Getdatasources
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getdatasources()
#' }
chemi_resolver_getdatasources <- function() {
  generic_request(
    query = NULL,
    endpoint = "resolver/getdatasources",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


