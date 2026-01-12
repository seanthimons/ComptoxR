#' Resolver Ccte Lists
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_ccte_lists()
#' }
chemi_resolver_ccte_lists <- function() {
  generic_request(
    query = NULL,
    endpoint = "resolver/ccte-lists",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


