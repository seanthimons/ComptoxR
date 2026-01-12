#' Resolver Universalharvest Cart
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Required parameter
#' @param info Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_universalharvest_cart(chemicals = "DTXSID7020182")
#' }
chemi_resolver_universalharvest_cart <- function(chemicals, info = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(info)) options$info <- info
  generic_chemi_request(
    query = chemicals,
    endpoint = "resolver/universalharvest_cart",
    options = options,
    tidy = FALSE
  )
}


