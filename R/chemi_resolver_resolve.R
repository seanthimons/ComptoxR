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
# Generated with specmill; do not edit by hand.
chemi_resolver_resolve <- function(mol = NULL, queries = NULL) {
  params <- base::list("mol" = mol, "queries" = queries)
  result <- generic_chemi_request(
    "query" = params[["mol"]],
    "endpoint" = "resolver/resolve",
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("queries" = params[["queries"]]))
      if (base::length(.body)) .body else base::list()
    }),
    "tidy" = FALSE
  )
  result
}
