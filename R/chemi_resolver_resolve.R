#' Resolver Resolve
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param mol Required parameter
#' @param queries Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolve(mol = "DTXSID7020182")
#' }
chemi_resolver_resolve <- function(mol, queries = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(queries)) options$queries <- queries
  generic_chemi_request(
    query = mol,
    endpoint = "resolver/resolve",
    options = options,
    tidy = FALSE
  )
}


