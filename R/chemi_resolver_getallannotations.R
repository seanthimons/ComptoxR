#' Resolver Getallannotations
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getallannotations()
#' }
chemi_resolver_getallannotations <- function() {
  generic_request(
    query = NULL,
    endpoint = "resolver/getallannotations",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


