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
# Generated with specmill; do not edit by hand.
chemi_resolver_lookupCASRN <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "endpoint" = "resolver/lookupCASRN",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("query" = params[["query"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
