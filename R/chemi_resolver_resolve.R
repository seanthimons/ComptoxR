#' Resolver Resolve
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param mol Optional parameter
#' @param queries Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolve(mol = "DTXSID1024122")
#' }
chemi_resolver_resolve <- function(mol = NULL, queries = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(queries)) {
    options$queries <- queries
  }
  result <- generic_chemi_request(
    query = mol,
    endpoint = "resolver/resolve",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
