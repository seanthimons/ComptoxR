#' Resolver lookupCASRN
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_lookupCASRN(query = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_resolver_lookupCASRN <- function(query) {
  params <- list("query" = query)
  result <- generic_request(
    "endpoint" = "resolver/lookupCASRN",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("query" = params[["query"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
