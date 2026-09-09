#' Resolver Resolve
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param mol Optional parameter
#' @param queries Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_resolve(mol = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_resolver_resolve <- function(mol = NULL, queries = NULL) {
  params <- list("mol" = mol, "queries" = queries)
  result <- generic_chemi_request(
    "query" = params[["mol"]],
    "endpoint" = "resolver/resolve",
    "options" = local({
      .body <- Filter(Negate(is.null), list("queries" = params[["queries"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
