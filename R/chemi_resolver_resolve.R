#' Resolver Resolve
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param queries Optional parameter
#' @param mol Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolve(queries = c("DTXSID901027719", "DTXSID20582510", "DTXSID80109469"))
#' }
chemi_resolver_resolve <- function(queries = NULL, mol = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(mol)) options$mol <- mol
  result <- generic_chemi_request(
    query = queries,
    endpoint = "resolver/resolve",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


