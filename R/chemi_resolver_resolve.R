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
#' chemi_resolver_resolve(queries = c("DTXSID8023638", "DTXSID8047004", "DTXSID301054196"))
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


